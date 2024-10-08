rem ----------------------------------------------------------------------------
rem Program: CUSTSTATEMENTS.prc
rem Description: Stored Procedure to create a jasper-based customer statement
rem              either on-demand, or batch
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

seterr sproc_error

declare BBjStoredProcedureData sp!
declare BBjRecordSet rs!
declare BBjRecordData data!

sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- get SPROC parameters

firm_id$ = sp!.getParameter("FIRM_ID")
statement_date$ = sp!.getParameter("STATEMENT_DATE")
customer$ = sp!.getParameter("CUSTOMER_ID")
age_basis$ = sp!.getParameter("AGE_BASIS")
amt_mask$ = sp!.getParameter("AMT_MASK")
cust_mask$ = sp!.getParameter("CUST_MASK")
customer_size = num(sp!.getParameter("CUST_SIZE"))
period_dates$ = sp!.getParameter("PERIOD_DATES")
barista_wd$ = sp!.getParameter("BARISTA_WD")

chdir barista_wd$

rem --- create the in memory recordset for return

dataTemplate$ = "firm_id:c(2),statement_date:C(10),customer_id:C(1*),cust_name:C(30),address1:C(30),address2:C(30),"
dataTemplate$ = dataTemplate$ + "address3:C(30),address4:C(30),address5:C(30),address6:C(30),"
dataTemplate$ = dataTemplate$ + "invoice_date:C(10),ar_inv_no:C(7),inv_type:C(11),invoice_amt:C(1*),trans_amt:C(1*),"
dataTemplate$ = DataTemplate$ + "invBalance:C(1*),aging_cur:C(1*),aging_30:C(1*),aging_60:C(1*),aging_90:C(1*),aging_120:C(1*),total_bal:C(1*),"
dataTemplate$ = dataTemplate$ + "remit1:C(30*),remit2:C(30*),remit3:C(30*),remit4:C(30*),payment_url:C(1*),"
dataTemplate$ = dataTemplate$ + "ar_address1:C(30*),ar_address2:C(30*),ar_address3:C(30*),ar_address4:C(30*),ar_phone_no:C(1*),ar_fax_no:C(1*)"

rs! = BBJAPI().createMemoryRecordSet(dataTemplate$)

rem --- open files

    files=5,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="arm-01",ids$[1]="ARM_CUSTMAST"
    files$[2]="art-01",ids$[2]="ART_INVHDR"
    files$[3]="art-11",ids$[3]="ART_INVDET"
    files$[4]="ars_report",ids$[4]="ARS_REPORT"
    files$[5]="ars_cc_custpmt",ids$[5]="ARS_CC_CUSTPMT"

    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],ids$[all],templates$[all],channels[all],batch,status
    if status then
        seterr 0
        x$=stbl("+THROWN_ERR","TRUE")   
        throw "File open error.",1001
    endif

    arm01=channels[1]
    art01=channels[2]
    art11=channels[3]
    ars_report=channels[4]
    ars_cc_custpmt=channels[5]
    
    rem --- Dimension string templates

	dim arm01$:templates$[1]
    dim art01$:templates$[2]
    dim art11$:templates$[3]
    dim ars_report$:templates$[4]
    dim ars_cc_custpmt$:templates$[5]
    
rem --- init   

gosub format_return_remit_addresses
gosub format_address_block

dim aging[5]

rem --- get payment_url for the cash_rec_cd used for customer payments (only one record allowed at present)

	readrecord(ars_cc_custpmt,key=firm_id$,dom=*next)
	while 1
		redim ars_cc_custpmt$
		readrecord(ars_cc_custpmt,end=*break)ars_cc_custpmt$
		if ars_cc_custpmt.firm_id$<>firm_id$ then break
		if ars_cc_custpmt.allow_cust_cc$="Y" then break
	wend

rem --- positional read

read record(art01, key = firm_id$ + "  " + customer$, dom=*next)

rem --- main loop
while 1
	
	read record(art01,end=*break)art01$

	if art01.firm_id$ <> firm_id$ then break
	if art01.customer_id$ <> customer$ then break
	
	if art01.invoice_date$ > statement_date$ then continue
	
    rem --- calculate invoice balance
	read record(art11, key=art01.firm_id$ + art01.ar_type$ + art01.customer_id$ + art01.ar_inv_no$, dom=*next)art11$
	trans_amt = 0
	while 1
		read record(art11,end=*break)art11$
		if art01.firm_id$ + art01.ar_type$ + art01.customer_id$ + art01.ar_inv_no$ <> art11.firm_id$ + art11.ar_type$ + art11.customer_id$ + art11.ar_inv_no$ then break
		if art11.trans_date$ <= statement_date$ then trans_amt = trans_amt + art11.trans_amt + art11.adjdisc_amt
	wend
	
    inv_type$="Invoice"
    if art01.invoice_type$="F" then inv_type$="Fin. Charge"
	
	invBalance = art01.invoice_amt + trans_amt

	if invBalance = 0 then continue
    total_bal = total_bal + invBalance

    rem --- Age this invoice

    agingdate$=art01.invoice_date$
    if age_basis$<>"I" agingdate$=art01.inv_due_date$
    invagepd=pos(agingdate$>period_dates$,8); rem determine invoice aging period for proper accumulation
    if invagepd=0 invagepd=5 else invagepd=int(invagepd/8)
    aging[invagepd]=aging[invagepd]+invBalance

	rem --- put data into recordset
    
	data! = rs!.getEmptyRecordData()
    data!.setFieldValue("FIRM_ID",firm_id$)
	data!.setFieldValue("STATEMENT_DATE",fndate$(statement_date$))
	data!.setFieldValue("CUSTOMER_ID",fnmask$(customer$(1,customer_size),cust_mask$))
rem	data!.setFieldValue("CUST_NAME",arm01.customer_name$)
	data!.setFieldValue("ADDRESS1", address$(1,30))
	data!.setFieldValue("ADDRESS2", address$(31,30))
	data!.setFieldValue("ADDRESS3", address$(61,30))
	data!.setFieldValue("ADDRESS4", address$(91,30))
	data!.setFieldValue("ADDRESS5", address$(121,30))
    data!.setFieldValue("ADDRESS6", address$(151,30))
	data!.setFieldValue("INVOICE_DATE",fndate$(art01.invoice_date$))
	data!.setFieldValue("AR_INV_NO",art01.ar_inv_no$)
	data!.setFieldValue("INV_TYPE",inv_type$)
	data!.setFieldValue("INVOICE_AMT",str(art01.invoice_amt:amt_mask$))
	data!.setFieldValue("TRANS_AMT",str(trans_amt:amt_mask$))
	data!.setFieldValue("INVBALANCE",str(invBalance:amt_mask$))
	data!.setFieldValue("AGING_CUR",str(aging[1]:amt_mask$))
	data!.setFieldValue("AGING_30",str(aging[2]:amt_mask$))
	data!.setFieldValue("AGING_60",str(aging[3]:amt_mask$))
	data!.setFieldValue("AGING_90",str(aging[4]:amt_mask$))
	data!.setFieldValue("AGING_120",str(aging[5]:amt_mask$))
    data!.setFieldValue("TOTAL_BAL",str(total_bal:amt_mask$))
    data!.setFieldValue("REMIT1", remit$((comp_remit_addr_len*0)+1,comp_remit_addr_len))
    data!.setFieldValue("REMIT2", remit$((comp_remit_addr_len*1)+1,comp_remit_addr_len))
    data!.setFieldValue("REMIT3", remit$((comp_remit_addr_len*2)+1,comp_remit_addr_len))
    data!.setFieldValue("REMIT4", remit$((comp_remit_addr_len*3)+1,comp_remit_addr_len))
	data!.setFieldValue("PAYMENT_URL", cvs(ars_cc_custpmt.payment_url$,2))
    data!.setFieldValue("AR_ADDRESS1", ar_address$((comp_remit_addr_len*0)+1,comp_remit_addr_len))
    data!.setFieldValue("AR_ADDRESS2", ar_address$((comp_remit_addr_len*1)+1,comp_remit_addr_len))
    data!.setFieldValue("AR_ADDRESS3", ar_address$((comp_remit_addr_len*2)+1,comp_remit_addr_len))
    data!.setFieldValue("AR_ADDRESS4", ar_address$((comp_remit_addr_len*3)+1,comp_remit_addr_len))
    data!.setFieldValue("AR_PHONE_NO", ar_phone_no$)
    data!.setFieldValue("AR_FAX_NO", ar_fax_no$)
	rs!.insert(data!)
    
wend

rem --- close files

close(arm01)
close(art01)
close(art11)
close(ars_report)

sp!.setRecordSet(rs!)
end

rem --- format address block for customer
format_address_block:

    address$=""
	read record(arm01,key=firm_id$ + customer$)arm01$
    address$=arm01.addr_line_1$+arm01.addr_line_2$+arm01.addr_line_3$+arm01.addr_line_4$+arm01.city$+arm01.state_code$+arm01.zip_code$+arm01.cntry_id$
    call pgmdir$+"adc_address.aon",address$,30,5,9,30
	dim tmp_address$(180)
	y=151
	for x=121 to 1 step -30
		if cvs(address$(x,30),2)<>""
			tmp_address$(y,30)=address$(x,30)
			y=y-30
		endif
	next x
	tmp_address$(y,30)=arm01.customer_name$
	address$=tmp_address$
    
return

rem --- format company and remit-to addresses
format_return_remit_addresses:

    comp_remit_addr_len=40
    find record (ars_report,key=firm_id$+"AR02",err=*next) ars_report$

    remit$=ars_report.remit_addr_1$+ars_report.remit_addr_2$+ars_report.remit_city$+ars_report.remit_state$+ars_report.remit_zip$
    call pgmdir$+"adc_address.aon",remit$,30,3,9,comp_remit_addr_len
    remit$=pad(ars_report.remit_name$,comp_remit_addr_len)+remit$

    ar_address$=ars_report.addr_line_1$+ars_report.addr_line_2$+ars_report.city$+ars_report.state_code$+ars_report.zip_code$
    call pgmdir$+"adc_address.aon",ar_address$,30,3,9,comp_remit_addr_len
    ar_address$=pad(ars_report.name$,comp_remit_addr_len)+ar_address$

    call stbl("+DIR_SYP")+"bac_getmask.bbj","T",cvs(ars_report.phone_no$,2),"",phone_mask$
    ar_phone_no$=str(cvs(ars_report.phone_no$,2):phone_mask$)
    ar_fax_no$=cvs(ars_report.fax_no$,2)
    if ar_fax_no$<>"" then ar_fax_no$=str(ar_fax_no$:phone_mask$)
    
return

rem --- Date/time handling functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

    def fnyy$(q$)=q$(3,2)
    def fnclock$(q$)=date(0:"%hz:%mz %p")
    def fntime$(q$)=date(0:"%Hz%mz")

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if cvs(q1$,2)="" return ""
        if q2$="" q2$=fill(len(q1$),"0")
        if pos("E"=cvs(q1$,4)) goto alpha_mask
:      else return str(-num(q1$,err=alpha_mask):q2$,err=alpha_mask)
alpha_mask:
        q=1
        q0=0
        while len(q2$(q))
            if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
            q=q+1
        wend
        if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
        return str(q1$:q2$)
    fnend

sproc_error:rem --- SPROC error trap/handler
    rd_err_text$="", err_num=err
    if tcb(2)=0 and tcb(5) then rd_err_text$=pgm(tcb(5),tcb(13),err=*next)
    x$=stbl("+THROWN_ERR","TRUE")   
    throw "["+pgm(-2)+"] "+str(tcb(5))+": "+rd_err_text$,err_num
    
std_exit:
    end

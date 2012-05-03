rem ----------------------------------------------------------------------------
rem Program: SFHARDCOPYTRANS.prc
rem Description: Stored Procedure to get the Shop Floor Hard Copy Transaction info into iReports
rem Used for Hard Copy, Traveler, Work Order Closed Detail and Work Order Detail
rem
rem Author(s): J. Brewer/ C. Johnson
rem Revised: 05.01.2012
rem
rem AddonSoftware
rem Copyright BASIS International Ltd.
rem ----------------------------------------------------------------------------

rem --- Set of utility methods

	use ::ado_func.src::func

rem --- Declare some variables ahead of time

	declare BBjStoredProcedureData sp!
	declare BBjRecordSet rs!
	declare BBjRecordData data!

rem --- Get the infomation object for the Stored Procedure

	sp! = BBjAPI().getFileSystem().getStoredProcedureData()

rem --- Get the IN parameters used by the procedure

	firm_id$ = sp!.getParameter("FIRM_ID")
	wo_loc$  = sp!.getParameter("WO_LOCATION")
	wo_no$ = sp!.getParameter("WO_NO")
	barista_wd$ = sp!.getParameter("BARISTA_WD")
	masks$ = sp!.getParameter("MASKS")
	
	sequence$ = sp!.getParameter("REPORT_SEQ")
	datefrom$ = sp!.getParameter("TRANS_DATEFROM")	
	datethru$ = sp!.getParameter("TRANS_DATETHRU")

rem --- masks$ will contain pairs of fields in a single string mask_name^mask|

	if len(masks$)>0
		if masks$(len(masks$),1)<>"|"
			masks$=masks$+"|"
		endif
	endif

rem ---
	
	sv_wd$=dir("")
	chdir barista_wd$

rem --- Create a memory record set to hold results.
rem --- Columns for the record set are defined using a string template
	temp$="TRANS_DATE:C(1*), SOURCE:C(1*), ITEM_VEND_OPER:C(1*), "
	temp$=temp$+"DESC:C(1*), PO_NUM:C(1*), COMPLETE_QTY:C(1*), SETUP_HRS:C(1*), "
	temp$=temp$+"UNITS:C(1*), RATE:C(1*), AMOUNT:C(1*)"	

	rs! = BBJAPI().createMemoryRecordSet(temp$)

rem --- Get Barista System Program directory

	sypdir$=""
	sypdir$=stbl("+DIR_SYP",err=*next)

rem --- Get masks

	pgmdir$=stbl("+DIR_PGM",err=*next)

	iv_cost_mask$=fngetmask$("iv_cost_mask","###,##0.0000-",masks$)
	ad_units_mask$=fngetmask$("ad_units_mask","#,###.00",masks$)
	vendor_mask$=fngetmask$("vendor_mask","000000",masks$)
	
	REM iv_cost_mask$="###,##0.0000-"
	bm_units_mask$="#,##0.00"
	bm_rate_mask$="###.00"
	sf_rate_mask$="###.00"
	bm_hours_mask$="#,##0.00"

rem --- Init totals

	tot_cost_ea=0
	tot_cost_tot=0

rem --- Open files with adc (Changed to bac once Barista is enhanced)

    files=9,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    files$[1]="ivm-01",    ids$[1]="IVM_ITEMMAST"
	files$[2]="arm-01",    ids$[2]="ARM_CUSTMAST"
	files$[3]="sfs_params",ids$[3]="SFS_PARAMS"
    files$[4]="sft-01",    ids$[4]="SFT_OPNOPRTR"
	files$[5]="sft-03",    ids$[5]="SFT_CLSOPRTR"
	files$[6]="sft-21",    ids$[6]="SFT_OPNMATTR"
    files$[7]="sft-23",    ids$[7]="SFT_CLSMATTR"
	files$[8]="sft-31",    ids$[8]="SFT_OPNSUBTR"
	files$[9]="sft-33",    ids$[9]="SFT_CLSSUBTR"
	
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit
	
    ivm_itemmast_dev=channels[1]
	arm_custmast=channels[2]
	sfs_params  =channels[3]
	
    sft01a_dev=channels[4]
	sft03a_dev=channels[5]
	sft21a_dev=channels[6]
    sft23a_dev=channels[7]
	sft31a_dev=channels[8]
	sft33a_dev=channels[9]

rem --- Dimension string templates

	dim ivm_itemmast$:templates$[1]
	dim arm_custmast$:templates$[2]
	dim sfs_params$:templates$[3]
    dim sft01a$:templates$[4]
	dim sft03a$:templates$[5]
    dim sft21a$:templates$[6]
    dim sft23a$:templates$[7]
    dim sft31a$:templates$[8]
    dim sft33a$:templates$[9]	
	
goto no_bac_open
rem --- Open Files via bac    (Changed to bac once Barista is enhanced)
    num_files = 9
    dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

	open_tables$[1]="IVM_ITEMMAST", open_opts$[1] = "OTA"
	open_tables$[2]="ARM_CUSTMAST", open_opts$[2] = "OTA"
	open_tables$[3]="SFS_PARAMS",   open_opts$[3] = "OTA"
	open_tables$[4]="SFT_OPNOPRTR", open_opts$[4] = "OTA"; rem sft-01
	open_tables$[5]="SFT_CLSOPRTR", open_opts$[5] = "OTA"; rem sft-03
	open_tables$[6]="SFT_OPNMATTR", open_opts$[6] = "OTA"; rem sft-21
	open_tables$[7]="SFT_CLSMATTR", open_opts$[7] = "OTA"; rem sft-23
	open_tables$[8]="SFT_OPNSUBTR", open_opts$[8] = "OTA"; rem sft-31
	open_tables$[9]="SFT_CLSSUBTR", open_opts$[9] = "OTA"; rem sft-33	
	
call sypdir$+"bac_open_tables.bbj",
:       open_beg,
:		open_end,
:		open_tables$[all],
:		open_opts$[all],
:		open_chans$[all],
:		open_tpls$[all],
:		table_chans$[all],
:		open_batch,
:		open_status$

	ivm_itemmast_dev  = num(open_chans$[1])
	arm_custmast = num(open_chans$[2])
	sfs_params = num(open_chans$[3])
	
	sft01a_dev = num(open_chans$[4])
	sft03a_dev = num(open_chans$[5])
	sft21a_dev = num(open_chans$[6])
	sft23a_dev = num(open_chans$[7])
	sft31a_dev = num(open_chans$[8])
	sft33a_dev = num(open_chans$[9])	
	
	rem --- templates
	dim ivm_itemmast$:open_tpls$[1]
	dim arm_custmast$:open_tpls$[2]
	dim sfs_params$:open_tpls$[3]
	
    dim sft01a$:open_tpls$[4]
	dim sft03a$:open_tpls$[5]
    dim sft21a$:open_tpls$[6]
    dim sft23a$:open_tpls$[7]
    dim sft31a$:open_tpls$[8]
    dim sft33a$:open_tpls$[9]	
	
no_bac_open:

rem --- Retrieve parameter records

        gls01a_key$=firm_id$+"GL00"
        find record (gls01a_dev,key=gls01a_key$,err=std_missing_params) gls01a$
	
		sfs01a_key$=firm_id$+"SF00"
        find record (sfs01a_dev,key=sfs01a_key$,err=std_missing_params) sfs01a$

rem --- Parameters

        bm$=sfs01a.bm_interface$
        op$=sfs01a.ar_interface$
        po$=sfs01a.po_interface$
        pr$=sfs01a.pr_interface$

rem --- Additional File Opens
		
		gosub addl_opens_adc; rem Change to bac once Barista's enhanced
		rem gosub addl_opens_bac; rem Change to bac once Barista's enhanced

Rem --- Find end date of SF's PREVIOUS period
        sf_prevper=num(sfs01a.current_per$)-1
        sf_prevper_yr=num(sfs01a.current_year$)
        if sf_prevper=0 then
			sf_prevper=num(gls01a.total_pers$)
			sf_prevper_yr=sf_prevper_yr-1
		endif
		
        call pgmdir$+"adc_perioddates.aon",gls01a_dev,sf_prevper,sf_prevper_yr,begdate$,sf_prevper_enddate$,status
        if status then goto std_exit
        sfs01a.current_per$=""
        sfs01a.current_year$=""
				
rem --- Build SQL statement

rem --- Get SQL view joining sfe01 with a mimic of legacy SFM-07 / WOM-07 / SFX_WOTRANXR
rem   - Narrow the query of that view using the selections from the OE form
rem   - This record set will be used as driver instead of sfe-01 and sfm-07

    sql_prep$=""
	where_clause$=""
	order_clause$=""
	
    sql_prep$=sql_prep$+"SELECT * "
    sql_prep$=sql_prep$+"FROM vw_WOs_with_tran as vwWOs "
	
	rem Modify the query of that view per user selections in OE form	

		where_clause$="WHERE vwWOs.firm_id+vwWOs.wo_location = '"+firm_id$+wo_loc$+"' AND "

	rem Limit recordset to WO being reported on
		where_clause$=where_clause$+"vwWOs.wo_no = '"+wo_no$+"' AND "

	rem Limit recordset to date range O/E selection
		if datefrom$<>"" where_clause$=where_clause$+"vwWOs.trans_date >= '"+datefrom$+"' AND "
		if datethru$<>"" where_clause$=where_clause$+"vwWOs.trans_date <= '"+datethru$+"' AND "

	rem Limit recordset to transaction type O/E selections
		if pos("M"=transtype$)=0 where_clause$=where_clause$+"vwWOs.record_id <> 'M' AND "
		if pos("O"=transtype$)=0 where_clause$=where_clause$+"vwWOs.record_id <> 'O' AND "
		if pos("S"=transtype$)=0 where_clause$=where_clause$+"vwWOs.record_id <> 'S' AND "
	
    rem Complete the WHERE clause
		where_clause$=cvs(where_clause$,2)
		if where_clause$(len(where_clause$)-2,3)="AND" where_clause$=where_clause$(1,len(where_clause$)-3)

	rem Complete the ORDER BY clause	
		order_clause$=order_clause$+" ORDER BY vwWOs.trans_date,vwWOs.record_id,vwWOs.trans_seq "
    
	rem Complete sql_prep$
		sql_prep$=sql_prep$+where_clause$+order_clause$	

	rem Exec the completed query

	sql_chan=sqlunt
	sqlopen(sql_chan,err=*next)stbl("+DBNAME")
	sqlprep(sql_chan)sql_prep$
	dim read_tpl$:sqltmpl(sql_chan)
	sqlexec(sql_chan)

rem --- Trip Read
rem ====================??????  needs lots more logic in here
rem ====================??????  have to read through the trans files 
rem ====================??????  masks are still issues
rem ====================??????  also need LOT/SER stuff 
rem ====================??????  also need totals

	while 1
		read_tpl$ = sqlfetch(sql_chan,end=*break)

		data! = rs!.getEmptyRecordData()

		rem --- Common to all transaction types
		data!.setFieldValue("TRANS_DATE",fndate$(sftran.trans_date$))
		data!.setFieldValue("SOURCE",read_tpl.record_id$)
		data!.setFieldValue("UNITS",str(sftran.units))
		data!.setFieldValue("RATE",str(sftran.unit_cost))
		data!.setFieldValue("AMOUNT",str(sftran.ext_cost))

        rem --- Based on Trans Type, fill type-specific fields
		ITEM_VEND_OPER$=""
		DESC$=""
		
		transtype=pos(read_tpl.record_id$="MOS")-1
		switch transtype
			case 0
				if read_tpl.wo_category$="I" 
					dim ivm_itemmast$:fattr(ivm_itemmast$)
					read record (ivm_itemmast_dev,key=firm_id$+read_tpl.item_id$,dom=*next) ivm_itemmast$
				endif

				data!.setFieldValue("ITEM_VEND_OPER",pad(cvs(sftran.item_id$,2),20))
				data!.setFieldValue("DESC",ivm_itemmast.item_desc$)
				data!.setFieldValue("PO_NUM","")
				data!.setFieldValue("COMPLETE_QTY","")
				data!.setFieldValue("SETUP_HRS","")			
				break
			case 1
			    OpDesc$="Invalid Op Code"
				find record (opcode_dev,key=firm_id$+sftran.op_code$,dom=label3) opcode$
				OpDesc$=opcode.code_desc$
				label3:
				find record (empcode_dev,key=firm_id$+sftran.employee_no$,dom=*next) empcode$

				data!.setFieldValue("ITEM_VEND_OPER",sftran.op_code$+"  "+OpDesc$)
				data!.setFieldValue("DESC",fnmask$(sftran.employee_no$,c5$)+" "+empcode.empl_surname$+empcode.empl_givname$)
				data!.setFieldValue("PO_NUM","")
				data!.setFieldValue("COMPLETE_QTY",str(sftran.complete_qty))
				data!.setFieldValue("SETUP_HRS",str(sftran.setup_time))		
				break
			case 2
				if po$="Y" then find record (apm01a_dev,key=firm_id$+sftran.vendor_id$,dom=*next) apm01a$

				data!.setFieldValue("ITEM_VEND_OPER",fnmask$(sftran.vendor_id$,c3$)+"  "+apm01a.vendor_name$)
				data!.setFieldValue("DESC",fnmask$(sftran.employee_no$,c5$)+" "+empcode.empl_surname$+empcode.empl_givname$)
				data!.setFieldValue("PO_NUM",sftran.po_no$)
				data!.setFieldValue("COMPLETE_QTY","")
				data!.setFieldValue("SETUP_HRS","")				    	
				break
			case default
				break
		swend

		rs!.insert(data!)
		tot_cost_ea=tot_cost_ea+read_tpl.unit_cost
		tot_cost_tot=tot_cost_tot+read_tpl.total_cost

	wend

rem --- Output Totals
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("COST_EA",fill(20,"_"))
	data!.setFieldValue("COST_TOT",fill(20,"_"))
	rs!.insert(data!)
	
	data! = rs!.getEmptyRecordData()
	data!.setFieldValue("ITEM","Total Materials")
	data!.setFieldValue("COST_EA",str(tot_cost_ea:iv_cost_mask$))
	data!.setFieldValue("COST_TOT",str(tot_cost_tot:sf_rate_mask$))
	rs!.insert(data!)
	
rem --- Tell the stored procedure to return the result set.

	sp!.setRecordSet(rs!)
	goto std_exit

rem --- Subroutines

rem --- Additional File Opens subroutines
addl_opens_adc:
    files=9,begfile=1,endfile=files
    dim files$[files],options$[files],ids$[files],templates$[files],channels[files]
    
	if op$="Y" then
        files$[1]="arm-01",     ids$[1]="ARM_CUSTMAST"
        files$[2]="ars_params", ids$[2]="ARS_PARAMS"
    endif
    if po$="Y" then 
        files$[3]="apm-01",     ids$[3]="APM_VENDMAST"
        files$[4]="aps_params", ids$[4]="APS_PARAMS"
    endif
    if bm$="Y" files$[5]="bmm-08", ids$[5]="BMC_OPCODES"
    if bm$="N" files$[5]="sfm-02:, ids$[5]="SFC_OPRTNCOD"
    if pr$="Y" then
        files$[6]="prs_params", ids$[6]="PRS_PARAMS"
        files$[7]="prm-01",     ids$[7]="PRM_EMPLMAST"
    endif
    if pr$="N" files$[7]="sfm-01", ids$[7]="SFM_EMPLMAST"
    if pos(ivs01a.lotser_flag$="LS") then
        files$[8]="sft-11",        ids$[8]="SFT_OPNLSTRN"
        files$[9]="sft-12",        ids$[9]="SFT_CLSLSTRN"
    endif
	
    call pgmdir$+"adc_fileopen.aon",action,begfile,endfile,files$[all],options$[all],
:                                   ids$[all],templates$[all],channels[all],batch,status
    if status goto std_exit

    arm01a_dev = channels[1]
    ars01a_dev = channels[2]
    apm01a_dev = channels[3]
    aps01a_dev = channels[4]
    opcode_dev = channels[5]
    prs01a_dev = channels[6]
    empcode_dev = channels[7]
    sft11a_dev = channels[8]
    sft12a_dev = channels[9]
		
    ivm_itemmast_dev=channels[1]
	arm_custmast=channels[2]
	sfs_params  =channels[3]

rem --- Dimension string templates

	if op$="Y" then
		dim arm01a$:templates$[1]
		dim ars01a$:templates$[2]
			
		find record (ars01a_dev,key=firm_id$+"AR00",dom=std_missing_params) ars01a$
        call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","I","",c1$,0,c1
    endif

	if po$="Y" then
		dim apm01a$:templates$[3]
		dim aps01a$:templates$[4]
			
		find record (aps01a_dev,key=firm_id$+"AP00") aps01a$
		call stbl("+DIR_PGM")+"adc_getmask.aon","","AP","I","",c3$,0,c3
    endif
		
	dim opcode$:templates$[5]
		
	if pr$="Y" then	
		dim prs01a$:templates$[6]

        find record (prs01a_dev,key=firm_id$+"PR00") prs01a$
        call stbl("+DIR_PGM")+"adc_getmask.aon","","PR","I","",c5$,0,c4
	else
        call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","I","",c5$,0,c4
	endif
		
	dim empcode$:templates$[7]
        
	dim sft11a$:templates$[8]
	dim sft12a$:templates$[9]

	return
	
addl_opens_bac:	
		num_files=9
		dim open_tables$[1:num_files], open_opts$[1:num_files], open_chans$[1:num_files], open_tpls$[1:num_files]

        if op$="Y" then
            open_tables$[1]="ARM_CUSTMAST", open_opts$[1]="OTA"; rem arm-01
            open_tables$[2]="ARS_PARAMS",   open_opts$[2]="OTA"; rem ars_params
        endif
        if po$="Y" then 
            open_tables$[3]="APM_VENDMAST", open_opts$[3]="OTA"; rem apm-01
            open_tables$[4]="APS_PARAMS",   open_opts$[4]="OTA"; rem aps_params
        endif
        if bm$="Y" open_tables$[5]="BMC_OPCODES",  open_opts$[5]="OTA"; rem bmm-08
        if bm$="N" open_tables$[5]="SFC_OPRTNCOD", open_opts$[5]="OTA"; rem sfm-02
        if pr$="Y" then
            open_tables$[6]="PRS_PARAMS",   open_opts$[6]="OTA"; rem prs_params
            open_tables$[7]="PRM_EMPLMAST", open_opts$[7]="OTA"; rem prm-01
        endif
        if pr$="N" open_tables$[7]="SFM_EMPLMAST", open_opts$[7]="OTA"; rem sfm-01
		
        if pos(ivs01a.lotser_flag$="LS") then
            open_tables$[8]="SFT_OPNLSTRN", open_opts$[8]="OTA"; rem sft-11
            open_tables$[9]="SFT_CLSLSTRN", open_opts$[9]="OTA"; rem sft-12
        endif
  	
		gosub open_tables
		
        arm01a_dev = num(open_chans$[1])
        ars01a_dev = num(open_chans$[2])
        apm01a_dev = num(open_chans$[3])
        aps01a_dev = num(open_chans$[4])
        opcode_dev = num(open_chans$[5])
        prs01a_dev = num(open_chans$[6])
        empcode_dev = num(open_chans$[7])
        sft11a_dev = num(open_chans$[8])
        sft12a_dev = num(open_chans$[9])
		
rem --- Dimension string templates & retrieve params (Add'l files)

		if op$="Y" then
			dim arm01a$:open_tpls$[1]
			dim ars01a$:open_tpls$[2]
			
			find record (ars01a_dev,key=firm_id$+"AR00",dom=std_missing_params) ars01a$
            call stbl("+DIR_PGM")+"adc_getmask.aon","","AR","I","",c1$,0,c1
        endif

		if po$="Y" then
			dim apm01a$:open_tpls$[3]
			dim aps01a$:open_tpls$[4]
			
			find record (aps01a_dev,key=firm_id$+"AP00") aps01a$
			call stbl("+DIR_PGM")+"adc_getmask.aon","","AP","I","",c3$,0,c3
        endif
		
		dim opcode$:open_tpls$[5]
		
		if pr$="Y" then	
			dim prs01a$:open_tpls$[6]

            find record (prs01a_dev,key=firm_id$+"PR00") prs01a$
            call stbl("+DIR_PGM")+"adc_getmask.aon","","PR","I","",c5$,0,c4
		else
            call stbl("+DIR_PGM")+"adc_getmask.aon","","SF","I","",c5$,0,c4
		endif
		
		dim empcode$:open_tpls$[7]
        
		sft11_tpls$=open_tpls$[8]; dim sft11a$:sft11_tpls$; rem Save tmpl for next o'lay
		sft12_tpls$=open_tpls$[9]; dim sft12a$:sft12_tpls$; rem Save tmpl for next o'lay		
	return    
	
rem --- Functions

    def fndate$(q$)
        q1$=""
        q1$=date(jul(num(q$(1,4)),num(q$(5,2)),num(q$(7,2)),err=*next),err=*next)
        if q1$="" q1$=q$
        return q1$
    fnend

rem --- fnmask$: Alphanumeric Masking Function (formerly fnf$)

    def fnmask$(q1$,q2$)
        if q2$="" q2$=fill(len(q1$),"0")
        return str(-num(q1$,err=*next):q2$,err=*next)
        q=1
        q0=0
        while len(q2$(q))
              if pos(q2$(q,1)="-()") q0=q0+1 else q2$(q,1)="X"
              q=q+1
        wend
        if len(q1$)>len(q2$)-q0 q1$=q1$(1,len(q2$)-q0)
        return str(q1$:q2$)
    fnend

	def fngetmask$(q1$,q2$,q3$)
		rem --- q1$=mask name, q2$=default mask if not found in mask string, q3$=mask string from parameters
		q$=q2$
		if len(q1$)=0 return q$
		if q1$(len(q1$),1)<>"^" q1$=q1$+"^"
		q=pos(q1$=q3$)
		if q=0 return q$
		q$=q3$(q)
		q=pos("^"=q$)
		q$=q$(q+1)
		q=pos("|"=q$)
		q$=q$(1,q-1)
		return q$
	fnend



	std_exit:
	
	end

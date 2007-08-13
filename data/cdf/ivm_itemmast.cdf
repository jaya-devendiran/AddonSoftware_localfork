[[IVM_ITEMMAST.BDEL]]
rem --- versions 6/7 have a program ivc.da used for deleting
rem --- need to codeport it;  after call, if status<>0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.SAFETY_STOCK.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.EOQ.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.ORDER_POINT.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.MAXIMUM_QTY.AVAL]]
if num(callpoint!.getUserInput())<0 then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.LEAD_TIME.AVAL]]
if num(callpoint!.getUserInput())<0 or fpt(num(callpoint!.getUserInput())) then callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.ABC_CODE.AVAL]]
if (callpoint!.getUserInput()<"A" or callpoint!.getUserInput()>"Z") and callpoint!.getUserInput()<>" " callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.AREC]]
rem -- get default values for new record from ivs-10D, IVS_DEFAULTS

ivs10_dev=fnget_dev("IVS_DEFAULTS")
dim ivs10d$:fnget_tpl$("IVS_DEFAULTS")

findrecord(ivs10_dev,key=firm_id$+"D",dom=*next)ivs10d$
callpoint!.setColumnData("IVM_ITEMMAST.PRODUCT_TYPE",ivs10d.product_type$)
callpoint!.setColumnData("IVM_ITEMMAST.UNIT_OF_SALE",ivs10d.unit_of_sale$)
callpoint!.setColumnData("IVM_ITEMMAST.PURCHASE_UM",ivs10d.purchase_um$)
callpoint!.setColumnData("IVM_ITEMMAST.TAXABLE_FLAG",ivs10d.taxable_flag$)
callpoint!.setColumnData("IVM_ITEMMAST.BUYER_CODE",ivs10d.buyer_code$)
callpoint!.setColumnData("IVM_ITEMMAST.LOTSER_ITEM",ivs10d.lotser_item$)
callpoint!.setColumnData("IVM_ITEMMAST.INVENTORIED",ivs10d.inventoried$)
callpoint!.setColumnData("IVM_ITEMMAST.ITEM_CLASS",ivs10d.item_class$)
callpoint!.setColumnData("IVM_ITEMMAST.STOCK_LEVEL",ivs10d.stock_level$)
callpoint!.setColumnData("IVM_ITEMMAST.ABC_CODE",ivs10d.abc_code$)
callpoint!.setColumnData("IVM_ITEMMAST.EOQ_CODE",ivs10d.eoq_code$)
callpoint!.setColumnData("IVM_ITEMMAST.ORD_PNT_CODE",ivs10d.ord_pnt_code$)
callpoint!.setColumnData("IVM_ITEMMAST.SAF_STK_CODE",ivs10d.saf_stk_code$)
callpoint!.setColumnData("IVM_ITEMMAST.ITEM_TYPE",ivs10d.item_type$)
callpoint!.setColumnData("IVM_ITEMMAST.GL_INV_ACCT",ivs10d.gl_inv_acct$)
callpoint!.setColumnData("IVM_ITEMMAST.GL_COGS_ACCT",ivs10d.gl_cogs_acct$)
callpoint!.setColumnData("IVM_ITEMMAST.GL_PUR_ACCT",ivs10d.gl_pur_acct$)
callpoint!.setColumnData("IVM_ITEMMAST.GL_PPV_ACCT",ivs10d.gl_ppv_acct$)
callpoint!.setColumnData("IVM_ITEMMAST.GL_INV_ADJ",ivs10d.gl_inv_adj$)
callpoint!.setColumnData("IVM_ITEMMAST.GL_COGS_ADJ",ivs10d.gl_cogs_adj$)

ivm10_dev=fnget_dev("IVC_PRODCODE")
dim ivm10a$:fnget_tpl$("IVC_PRODCODE")

findrecord(ivm10_dev,key=firm_id$+"A"+ivs10d.product_type$,dom=*next)ivm10a$
callpoint!.setColumnData("IVM_ITEMMAST.SA_LEVEL",ivm10a.sa_level$)

callpoint!.setStatus("REFRESH")
[[IVM_ITEMMAST.WEIGHT.AVAL]]
if num(callpoint!.getUserInput())<0 or num(callpoint!.getUserInput())>9999.99 callpoint!.setStatus("ABORT")
[[IVM_ITEMMAST.AENA]]
call dir_pgm$+"adc_application.aon","GL",info$[all]
gl$=info$[20]

if gl$="Y" 
	call dir_pgm$+"adc_application.aon","IV",info$[all]
	gl$=info$[9]; rem --- if gl installed, does it interface to inventory?
endif

di$="N"
dim ars01a$:fnget_tpl$("ARS_PARAMS")
if ar$="Y"
	ars01a_key$=firm_id$+"AR00"
	find record (ads01_dev,key=ars01a_key$,err=std_missing_params) ars01a$
	di$=ars01a.dist_by_item$
	if gl$="N" di$="N"
endif

rem --- if di$="N" and gl$="Y" leave GL tab/fields alone, otherwise disable them
if di$<>"N" or gl$<>"Y"
	fields_to_disable$="GL_INV_ACCT     GL_COGS_ACCT    GL_PUR_ACCT     GL_PPV_ACCT     GL_INV_ADJ      GL_COGS_ADJ     "
	wmap$=callpoint!.getAbleMap()
	ctl_stat$="I"
	for wfield=1 to len(fields_to_disable$)-1 step 16
		ctl_name$="IVM_ITEMMAST."+cvs(fields_to_disable$(wfield,16),3)					
		wctl$=str(num(callpoint!.getTableColumnAttribute(ctl_name$,"CTLI")):"00000")
		wpos=pos(wctl$=wmap$,8)
		wmap$(wpos+6,1)=ctl_stat$
	next wfield
	callpoint!.setAbleMap(wmap$)
	callpoint!.setStatus("ABLEMAP")
endif
[[IVM_ITEMMAST.ASHO]]
callpoint!.setStatus("ABLEMAP-REFRESH")
[[IVM_ITEMMAST.<CUSTOM>]]
#include std_missing_params.src
[[IVM_ITEMMAST.BSHO]]
rem --- Open/Lock files

files=2,begfile=1,endfile=files
dim files$[files],options$[files],chans$[files],templates$[files]
files$[1]="IVS_PARAMS";rem --- ads-01
files$[2]="IVS_DEFAULTS";rem --- ivs-10 (D)

for wkx=begfile to endfile
	options$[wkx]="OTA"
next wkx

call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 chans$[all],templates$[all],table_chans$[all],batch,status$

if status$<>""  goto std_exit

ads01_dev=num(chans$[1])

rem --- Retrieve miscellaneous templates

files=4,begfile=1,endfile=files
dim ids$[files],templates$[files]
ids$[1]="ivs-01A"
ids$[2]="gls-01A"
ids$[3]="ars-01A"

call dir_pgm$+"bac_template.bbj",begfile,endfile,ids$[all],templates$[all],status
if status goto std_exit

rem --- Dimension miscellaneous string templates

dim ivs01a$:templates$[1],gls01a$:templates$[2],ars01a$:templates$[3]

rem --- init/parameters

disable_str$=""
enable_str$=""
dim info$[20]

ivs01a_key$=firm_id$+"IV00"
find record (ads01_dev,key=ivs01a_key$,err=std_missing_params) ivs01a$

gls01a_key$=firm_id$+"GL00"
find record (ads01_dev,key=gls01a_key$,err=std_missing_params) gls01a$

call dir_pgm$+"adc_application.aon","AR",info$[all]
ar$=info$[20]
call dir_pgm$+"adc_application.aon","AP",info$[all]
ap$=info$[20]
call dir_pgm$+"adc_application.aon","BM",info$[all]
bm$=info$[20]
call dir_pgm$+"adc_application.aon","GL",info$[all]
gl$=info$[20]
call dir_pgm$+"adc_application.aon","OP",info$[all]
op$=info$[20]
call dir_pgm$+"adc_application.aon","PO",info$[all]
po$=info$[20]
call dir_pgm$+"adc_application.aon","SF",info$[all]
wo$=info$[20]
call dir_pgm$+"adc_application.aon","SA",info$[all]
sa$=info$[20]


if ap$<>"Y" disable_str$=disable_str$+"IVM_ITEMVEND;"; rem --- this is a detail window, give alias name
if pos(ivs01a.lifofifo$="LF")=0 disable_str$=disable_str$+"LIFO;"; rem --- these are AOPTions, give AOPT code only
if pos(ivs01a.lotser_flag$="LS")=0 disable_str$=disable_str$+"LTRN;"
if op$<>"Y" disable_str$=disable_str$+"SORD;"
if po$<>"Y" disable_str$=disable_str$+"PORD;"
				
if disable_str$<>"" call dir_pgm$+"rdm_enable_pop.aon",Form!,enable_str$,disable_str$

rem --- additional file opens, depending on which apps are installed, param values, etc.

more_files$="",files=0
if pos(ivs01a.lifofifo$="LF")<>0 then more_files$=more_files$+"IVM_ITEMTIER;",files=files+1
if pos(ivs01a.lotser_flag$="LS")<>0 then more_files$=more_files$+"IVM_LSMASTER;IVM_LSACT;IVT_LSTRANS;",files=files+3
if ivs01a.master_flag_01$="Y" or ivs01a.master_flag_02$="Y" or ivs01a.master_flag_03$="Y"
	more_files$=more_files$+"IVM_DESCRIP1;IVM_DESCRIP2;IVM_DESCRIP3;"
	files=files+3
endif 
if ar$="Y" then more_files$=more_files$+"ARM_CUSTMAST;ARC_DISTCODE;",files=files+2
if bm$="Y" then more_files$=more_files$+"BMM_BILLMAST;BMM_BILLMAT;",files=files+2
if op$="Y" then more_files$=more_files$+"OPE_ORDHDR;OPE_ORDDET;OPE_ORDITEM;",files=files+3
if po$="Y" then more_files$=more_files$+"POE_REQHDR;POE_POHDR;POE_REQDET;POE_PODET;"
:	+"POC_LINECODES;POT_RECHDR;POT_RECDET;",files=files+7
if wo$="Y" then more_files$=more_files$+"SFE_WOMASTER;SFE_WOMATL;",files=files+2

if files
	begfile=1,endfile=files,wfile=1
	dim files$[files],options$[files],chans$[files],templates$[files]
	while pos(";"=more_files$)
		files$[wfile]=more_files$(1,pos(";"=more_files$)-1)
		more_files$=more_files$(pos(";"=more_files$)+1)
		wfile=wfile+1

	wend

	for wkx=begfile to endfile
		options$[wkx]="OTA"
	next wkx

	call dir_pgm$+"bac_open_tables.bbj",begfile,endfile,files$[all],options$[all],
:                                 	chans$[all],templates$[all],table_chans$[all],batch,status$

	if status$<>"" goto std_exit

endif
[[IVM_ITEMMAST.AOPT-PORD]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID"
dflt_data$[1,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_OPENPO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-SORD]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID"
dflt_data$[1,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_OPENSO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-LTRN]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_LSTRANHIST",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-IHST]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_TRANSHIST",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]
[[IVM_ITEMMAST.AOPT-LIFO]]
cp_item_id$=callpoint!.getColumnData("IVM_ITEMMAST.ITEM_ID")
user_id$=stbl("+USER_ID")
dim dflt_data$[2,1]
dflt_data$[1,0]="ITEM_ID_1"
dflt_data$[1,1]=cp_item_id$
dflt_data$[2,0]="ITEM_ID_2"
dflt_data$[2,1]=cp_item_id$
call stbl("+DIR_SYP")+"bam_run_prog.bbj",
:	"IVR_LIFOFIFO",
:	user_id$,
:	"",
:	"",
:	table_chans$[all],
:	"",
:	dflt_data$[all]

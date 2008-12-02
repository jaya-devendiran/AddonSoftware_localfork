[[GLR_FINANCIALS.ASVA]]
rem "update GLE_FINANCIALRPT (gle-04) -- remove/write -- based on what's checked in the grid
rem "also update GLS_FINANCIALS w/ period/year from form, first updt sequence "9", first print flag "N"

gle04_dev=fnget_dev("GLE_FINANCIALRPT")
dim gle04a$:fnget_tpl$("GLE_FINANCIALRPT")
recs_written=0

gridReports!=UserObj!.getItem(num(user_tpl.gridReportsOfst$))
gridRows=gridReports!.getNumRows()

if gridRows
	for row=0 to gridRows-1
		if gridReports!.getCellState(row,0)=0
			remove(gle04_dev,key=firm_id$+gridReports!.getCellText(row,1),dom=*next)
		else
			gle04a.firm_id$=firm_id$,gle04a.gl_rpt_no$=gridReports!.getCellText(row,1)
			write record(gle04_dev,key=firm_id$+gle04a.gl_rpt_no$)gle04a$
			recs_written=recs_written+1
		endif
	next row
endif

if recs_written=0
	msg_id$="GL_FIN_SELECT"
	gosub disp_message
	callpoint!.setStatus("ABORT")
else
	close (gle04_dev);rem "will re-open and lock in gle_financials (pgm run from here)
endif
[[GLR_FINANCIALS.ARAR]]
gls01_dev=fnget_dev("GLS_PARAMS")
gls01_tpl$=fnget_tpl$("GLS_PARAMS")
dim gls01a$:gls01_tpl$

read record (gls01_dev,key=firm_id$+"GL00",dom=std_missing_params)gls01a$
callpoint!.setColumnData("GLR_FINANCIALS.PERIOD",gls01a.current_per$)
callpoint!.setColumnData("GLR_FINANCIALS.YEAR",gls01a.current_year$)
callpoint!.setTableColumnAttribute("GLR_FINANCIALS.PERIOD","MINV","01")
callpoint!.setTableColumnAttribute("GLR_FINANCIALS.PERIOD","MAXV",str(num(gls01a.total_pers$):"00"))

callpoint!.setStatus("REFRESH")
[[GLR_FINANCIALS.ACUS]]
rem process custom event -- used in this pgm to select/de-select checkboxes in grid
rem see basis docs notice() function, noticetpl() function, notify event, grid control notify events for more info
rem this routine is executed when callbacks have been set to run a "custom event"
rem analyze gui_event$ and notice$ to see which control's callback triggered the event, and what kind
rem of event it is... in this case, we're toggling checkboxes on/off in form grid control

dim gui_event$:tmpl(gui_dev)
dim notify_base$:noticetpl(0,0)
gui_event$=SysGUI!.getLastEventString()
ctl_ID=dec(gui_event.ID$)
if ctl_ID=num(user_tpl.gridReportsCtlID$)
	if gui_event.code$="N"
		notify_base$=notice(gui_dev,gui_event.x%)
		dim notice$:noticetpl(notify_base.objtype%,gui_event.flags%)
		notice$=notify_base$
	endif
	switch notice.code
		case 12;rem grid_key_press
			if notice.wparam=32 gosub switch_value
		break
		case 14;rem grid_mouse_up
			if notice.col=0 gosub switch_value
		break
	swend
endif
[[GLR_FINANCIALS.ASIZ]]
if UserObj!<>null()
	gridReports!=UserObj!.getItem(num(user_tpl.gridReportsOfst$))
	gridReports!.setColumnWidth(0,25)
	gridReports!.setColumnWidth(1,50)
	gridReports!.setSize(Form!.getWidth()-(gridReports!.getX()*2),Form!.getHeight()-(gridReports!.getY()+40))
	gridReports!.setFitToGrid(1)

endif
[[GLR_FINANCIALS.<CUSTOM>]]
resize_window: rem --- Resize window based on new controls

	controls! = Form!.getAllControls()
	ScreenSize! = SysGUI!.getSystemMetrics().getScreenSize()
	screen_width = ScreenSize!.width - 40
	screen_height = ScreenSize!.height - 40
	group_box = 21
	push_button = 11
	new_width = Form!.getWidth()
	new_height = Form!.getHeight()
	extra_width = 10
	extra_height = 10
	no_buttons_yet = 1

	rem --- Roll throught all controls, setting the max width and height
	for i=0 to controls!.size() - 1
		this_ctrl! = controls!.getItem(i)
		type = this_ctrl!.getControlType()

		rem --- Group boxes dimesions can mess up the calculation
		if type = group_box then continue
		
		rem --- Push Buttons (e.g. "OK", "Cancel") need extra room at the bottom
		if type = push_button then
			if no_buttons_yet then
				extra_height = extra_height + this_ctrl!.getHeight() + 5
				no_buttons_yet = 0
			endif
		else
		
			rem --- Most controls go here
			new_width  = max( new_width,  this_ctrl!.getX() + this_ctrl!.getWidth() )
			new_height = max( new_height, this_ctrl!.getY() + this_ctrl!.getHeight() )
		endif
		
	next i

	rem --- Set new size, but not bigger than the screen
	new_width = min( screen_width, new_width + extra_width )
	new_height = min( screen_height, new_height + extra_height )
	Form!.setSize(new_width, new_height)
	
	rem --- Will the form still fit on the screen?
	new_position = 0
	form_x = Form!.getX()
	form_y = Form!.getY()
	
	if form_x + new_width > screen_width then
		form_x = int( (screen_width - new_width) / 2 )
		new_position = 1
	endif
	
	if form_y + new_height > screen_height then
		form_y = int( (screen_height - new_height) / 2 )
		new_position = 1
	endif
	
	if new_position then
		Form!.setLocation(form_x, form_y)
	endif

return

format_grid:

dim attr_def_col_str$[0,0]
attr_def_col_str$[0,0]=callpoint!.getColumnAttributeTypes()
def_rpts_cols=num(user_tpl.gridReportsCols$)
num_rpts_rows=num(user_tpl.gridReportsRows$)
dim attr_rpts_col$[def_rpts_cols,len(attr_def_col_str$[0,0])/5]
attr_rpts_col$[1,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="SELECT"
attr_rpts_col$[1,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]=""
attr_rpts_col$[1,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="25"
attr_rpts_col$[1,fnstr_pos("MAXL",attr_def_col_str$[0,0],5)]="1"
attr_rpts_col$[1,fnstr_pos("CTYP",attr_def_col_str$[0,0],5)]="C"

attr_rpts_col$[2,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="REPT_NO"
attr_rpts_col$[2,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Report"
attr_rpts_col$[2,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="50"

attr_rpts_col$[3,fnstr_pos("DVAR",attr_def_col_str$[0,0],5)]="DESC"
attr_rpts_col$[3,fnstr_pos("LABS",attr_def_col_str$[0,0],5)]="Description"
attr_rpts_col$[3,fnstr_pos("CTLW",attr_def_col_str$[0,0],5)]="225"

for curr_attr=1 to def_rpts_cols

	attr_rpts_col$[0,1]=attr_rpts_col$[0,1]+pad("FIN_RPTS."+attr_rpts_col$[curr_attr,
:		fnstr_pos("DVAR",attr_def_col_str$[0,0],5)],40)

next curr_attr

attr_disp_col$=attr_rpts_col$[0,1]

call stbl("+DIR_SYP")+"bam_grid_init.bbj",gui_dev,gridReports!,"COLH-LINES-LIGHT-AUTO-MULTI-SIZEC-DATES-CHECKS",num_rpts_rows,
:	attr_def_col_str$[all],attr_disp_col$,attr_rpts_col$[all]


return

fill_grid:

	SysGUI!.setRepaintEnabled(0)
	gridReports!=UserObj!.getItem(num(user_tpl.gridReportsOfst$))
	minrows=num(user_tpl.gridReportsRows$)
	if vectReports!.size()

		numrow=vectReports!.size()/gridReports!.getNumColumns()
		gridReports!.clearMainGrid()
		gridReports!.setColumnStyle(0,SysGUI!.GRID_STYLE_UNCHECKED)
		gridReports!.setNumRows(numrow)
		gridReports!.setCellText(0,0,vectReports!)
		if vectReportsSel!.size()
			for wk=0 to vectReportsSel!.size()-1
				if vectReportsSel!.getItem(wk)="Y"
					gridReports!.setCellStyle(wk,0,SysGUI!.GRID_STYLE_CHECKED)
				endif
			next wk
		endif
		gridReports!.resort()
		rem gridReports!.setSelectedRow(0)
		rem gridReports!.setSelectedColumn(1)
	endif
	SysGUI!.setRepaintEnabled(1)
return

create_reports_vector:

	more=1
	read (glm12_dev,key=firm_id$,dom=*next)
	vectReports!=SysGUI!.makeVector()
	vectReportsSel!=SysGUI!.makeVector()

	while more
		readrecord (glm12_dev,end=*break)glm12a$
		if pos(firm_id$=glm12a$)<>1 then break
		vectReports!.addItem("")
		vectReports!.addItem(glm12a.gl_rpt_no$)
		vectReports!.addItem(glm12a.gl_rpt_desc$)
		vectReportsSel!.addItem("N")
	wend
	
return

switch_value:rem --- Switch Check Values

	SysGUI!.setRepaintEnabled(0)
	gridReports!=UserObj!.getItem(num(user_tpl.gridReportsOfst$))
	TempRows!=gridReports!.getSelectedRows()
	if TempRows!.size()>0
		for curr_row=1 to TempRows!.size()
			if gridReports!.getCellState(TempRows!.getItem(curr_row-1),0)=0
				gridReports!.setCellState(TempRows!.getItem(curr_row-1),0,1)
				else
				gridReports!.setCellState(num(TempRows!.getItem(curr_row-1)),0,0)
			endif
		next curr_row
	endif

	SysGUI!.setRepaintEnabled(1)

	return
		
#include std_missing_params.src
[[GLR_FINANCIALS.AWIN]]
rem --- Open/Lock files

num_files=4
dim open_tables$[1:num_files],open_opts$[1:num_files],open_chans$[1:num_files],open_tpls$[1:num_files]
open_tables$[1]="GLS_PARAMS",open_opts$[1]="OTA"
open_tables$[2]="GLM_FINMASTER",open_opts$[2]="OTA"
open_tables$[3]="GLE_FINANCIALRPT",open_opts$[3]="OTA"
open_tables$[4]="GLS_FINANCIALS",open_opts$[4]="OTA"

gosub open_tables

gls01_dev=num(open_chans$[1]),gls01_tpl$=open_tpls$[1]
glm12_dev=num(open_chans$[2]),glm12_tpl$=open_tpls$[2]
gle04_dev=num(open_chans$[3]),gle04_tpl$=open_tpls$[3]
gls01c_dev=num(open_chans$[4]),gls01c_tpl$=open_tpls$[4]

rem --- Dimension string templates

    dim gls01a$:gls01_tpl$,glm12a$:glm12_tpl$,gle04a$:gle04_tpl$

call stbl("+DIR_PGM")+"adc_clearfile.aon",gle04_dev

rem --- add grid to store report master records, with checkboxes for user to select one or more reports

user_tpl_str$="gridReportsOfst:c(5),gridReportsCols:c(5),gridReportsRows:c(5),gridReportsCtlID:c(5)," +
:		    	"vectReportsOfst:c(5),vectReportsSelOfst:c(5)"
dim user_tpl$:user_tpl_str$

UserObj!=SysGUI!.makeVector()
nxt_ctlID=num(stbl("+CUSTOM_CTL",err=std_error))

gridReports!=Form!.addGrid(nxt_ctlID,5,100,300,200)
user_tpl.gridReportsCtlID$=str(nxt_ctlID)
user_tpl.gridReportsCols$="3"
user_tpl.gridReportsRows$="8"
user_tpl.gridReportsOfst$="0"
user_tpl.vectReportsOfst$="1"
user_tpl.vectReportsSelOfst$="2"

gosub format_grid

UserObj!.addItem(gridReports!)
UserObj!.addItem(SysGUI!.makeVector());rem vector of recs from Fin Rpt Master
UserObj!.addItem(SysGUI!.makeVector());rem vector of which reports are selected

rem --- misc other init
gridReports!.setColumnEditable(0,1)
gridReports!.setTabAction(SysGUI!.GRID_NAVIGATE_LEGACY)

gosub create_reports_vector
gosub fill_grid
gosub resize_window

rem --- set callbacks - processed in ACUS callpoint
gridReports!.setCallback(gridReports!.ON_GRID_KEY_PRESS,"custom_event")
gridReports!.setCallback(gridReports!.ON_GRID_MOUSE_UP,"custom_event")

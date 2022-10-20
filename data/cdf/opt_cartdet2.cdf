[[OPT_CARTDET2.AGDR]]
rem --- Initialize CARTON_DSP with CARTON_NO
	callpoint!.setColumnData("<<DISPLAY>>.CARTON_DSP",callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO"),1)

rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	qty_packed=num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
	gosub getPickedQty
	gosub getUnpackedQty
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	curr_row=num(callpoint!.getValidationRow())
	packed_col=callpoint!.getDevObject("packed_col")

	if qty_packed<unpackedQty then
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("boldFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("redColor"))
	else
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("plainFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("blackColor"))
	endif

[[OPT_CARTDET2.AGDS]]
rem --- Skip if the grid is empty
	if GridVect!.size()=0 then break

rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	dim optCartDet$:fnget_tpl$("OPT_CARTDET")
	optCartDet2_dev=fnget_dev("OPT_CARTDET2")
	dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	packed_col=callpoint!.getDevObject("packed_col")
	for row=0 to GridVect!.size()-1
		qty_picked=0
		redim optCartDet$
		optCartDet$=GridVect!.getItem(row)
		orddet_seq_ref$=optCartDet.orddet_seq_ref$
		optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
		read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS_ORDDET",dom=*next)
		while 1
			optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
			if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
			readrecord(optFillmntDet_dev)optFillmntDet$
			qty_picked=optFillmntDet.qty_picked
			break
		wend

		alreadyPacked=0
		optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
		read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
		while 1
			optCartDet2_key$=key(optCartDet2_dev,end=*break)
			if pos(optCartDet2_trip$=optCartDet2_key$)<>1 then break
			readrecord(optCartDet2_dev)optCartDet2$
			alreadyPacked=alreadyPacked+optCartDet2.qty_packed
		wend
		unpackedQty=qty_picked-alreadyPacked

		if unpackedQty>0 then
			packCartonGrid!.setCellFont(row,packed_col,callpoint!.getDevObject("boldFont"))
			packCartonGrid!.setCellForeColor(row,packed_col,callpoint!.getDevObject("redColor"))
		else
			packCartonGrid!.setCellFont(row,packed_col,callpoint!.getDevObject("plainFont"))
			packCartonGrid!.setCellForeColor(row,packed_col,callpoint!.getDevObject("blackColor"))
		endif
	next row
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)

[[OPT_CARTDET2.AOPT-PKLS]]
rem --- Initialize grid with unpacked picked lots/serials in OPT_FILLMNTLSDET
	ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET2.ORDDET_SEQ_REF")
	optCartLsDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$

	optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
	dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
	read(optCartLsDet2_dev,key=optCartLsDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
	optCartLsDet2_key$=key(optCartLsDet2_dev,end=*next)
	if pos(optCartLsDet2_trip$=optCartLsDet2_key$)=1 then
		rem --- Grid already initialized
	else
		rem --- Ask if they want to pack all remaining unpacked lot/serial numbers picked for this item
		msg_id$ = "OP_PACK_UNPACKED"
		gosub disp_message
		if msg_opt$="Y" then
			rem --- Initialize grid
			seqNo=0
			optFillmntLsDet_dev=fnget_dev("OPT_FILLMNTLSDET")
			dim optFillmntLsDet$:fnget_tpl$("OPT_FILLMNTLSDET")
			optFillmntDet_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$

			read(optFillmntLsDet_dev,key=optFillmntDet_key$,knum="AO_STATUS",dom=*next)
			while 1
				optFillmntLsDet_key$=key(optFillmntLsDet_dev,end=*break)
				if pos(optFillmntDet_key$=optFillmntLsDet_key$)<>1 then break
				readrecord(optFillmntLsDet_dev)optFillmntLsDet$

				rem --- Skip if already fully packed in other cartoons
				alreadyPacked=0
				optCartLsDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
				read(optCartLsDet2_dev,key=optCartLsDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
				while 1
					optCartLsDet2_key$=key(optCartLsDet2_dev,end=*break)
					if pos(optCartLsDet2_trip$=optCartLsDet2_key$)<>1 then break
					readrecord(optCartLsDet2_dev)optCartLsDet2$
					if optCartLsDet2.lotser_no$<>optFillmntLsDet.lotser_no$ then continue
					alreadyPacked=alreadyPacked+optCartLsDet2.qty_packed
				wend
				if alreadyPacked>=optFillmntLsDet.qty_picked then continue

				seqNo=seqNo+1
				redim optCartLsDet2$
				optCartLsDet2.firm_id$=firm_id$
				optCartLsDet2.ar_type$=ar_type$
				optCartLsDet2.customer_id$=customer_id$
				optCartLsDet2.order_no$=order_no$
				optCartLsDet2.ar_inv_no$=ar_inv_no$
				optCartLsDet2.carton_no$=carton_no$
				optCartLsDet2.orddet_seq_ref$=orddet_seq_ref$
				optCartLsDet2.sequence_no$=str(seqNo,"000")
				optCartLsDet2.lotser_no$=optFillmntLsDet.lotser_no$
				optCartLsDet2.created_user$=sysinfo.user_id$
				optCartLsDet2.created_date$=date(0:"%Yd%Mz%Dz")
				optCartLsDet2.created_time$=date(0:"%Hz%mz")
				optCartLsDet2.trans_status$="E"
				optCartLsDet2.qty_packed=optFillmntLsDet.qty_picked-alreadyPacked
				writerecord(optCartLsDet2_dev)optCartLsDet2$
			wend
		endif
	endif

rem --- Launch Packing Carton Lot/Serial Detail grid

		optCartLsDet2_key$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$

		rem --- Pass additional info needed in OPT_CARTLSDET
		callpoint!.setDevObject("item_id",callpoint!.getColumnData("OPT_CARTDET2.ITEM_ID"))

		call stbl("+DIR_SYP") + "bam_run_prog.bbj", 
:			"OPT_CARTLSDET2", 
:			stbl("+USER_ID"), 
:			"MNT" ,
:			optCartLsDet2_key$, 
:			table_chans$[all], 
:			dflt_data$[all]

		callpoint!.setStatus("ACTIVATE")

rem --- Has the total quantity packed changed?
	start_qty_packed=num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
	total_packed=callpoint!.getDevObject("total_packed")
	if total_packed<>start_qty_packed then
		callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(total_packed),1)
		callpoint!.setStatus("MODIFIED")
		callpoint!.setFocus(callpoint!.getValidationRow(),"OPT_CARTDET2.QTY_PACKED",1)
	endif

[[OPT_CARTDET2.AREC]]
rem ---Initialize fields needed for CARTON_NO lookup
	call stbl("+DIR_SYP")+"bac_key_template.bbj","OPT_CARTDET2","AO_ORDDET_CART",key_tpl$,table_chans$[all],status$
	dim optCartDet2_keyPrefix$:key_tpl$
	optCartDet2_keyPrefix$=callpoint!.getKeyPrefix()
	callpoint!.setColumnData("OPT_CARTDET2.AR_TYPE",optCartDet2_keyPrefix.ar_type$)
	callpoint!.setColumnData("OPT_CARTDET2.CUSTOMER_ID",optCartDet2_keyPrefix.customer_id$)
	callpoint!.setColumnData("OPT_CARTDET2.ORDER_NO",optCartDet2_keyPrefix.order_no$)
	callpoint!.setColumnData("OPT_CARTDET2.AR_INV_NO",optCartDet2_keyPrefix.ar_inv_no$)
	callpoint!.setColumnData("OPT_CARTDET2.ORDDET_SEQ_REF",optCartDet2_keyPrefix.orddet_seq_ref$)

rem --- Initialize RTP trans_status and created fields
	rem --- TRANS_STATUS set to "E" via form Preset Value
	callpoint!.setColumnData("OPT_CARTDET2.CREATED_USER",sysinfo.user_id$)
	callpoint!.setColumnData("OPT_CARTDET2.CREATED_DATE",date(0:"%Yd%Mz%Dz"))
	callpoint!.setColumnData("OPT_CARTDET2.CREATED_TIME",date(0:"%Hz%mz"))

rem --- Buttons start disabled
	callpoint!.setOptionEnabled("PKLS",0)

[[OPT_CARTDET2.ASHO]]
rem --- Set Lot/Serial button up properly
	switch pos(callpoint!.getDevObject("lotser_flag")="LS")
		case 1; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACK")+" "+Translate!.getTranslation("AON_LOT")); break
		case 2; callpoint!.setOptionText("PKLS",Translate!.getTranslation("AON_PACK")+" "+Translate!.getTranslation("AON_SERIAL")); break
		case default; callpoint!.setOptionEnabled("PKLS",0); break
	swend

rem --- Get and hold on to column for qty_packed
	packCartonGrid!=Form!.getControl(num(stbl("+GRID_CTL")))
	callpoint!.setDevObject("packCartonGrid",packCartonGrid!)
	packed_hdr$=callpoint!.getTableColumnAttribute("OPT_CARTDET2.QTY_PACKED","LABS")
	packed_col=util.getGridColumnNumber(packCartonGrid!,packed_hdr$)
	callpoint!.setDevObject("packed_col",packed_col)

[[OPT_CARTDET2.AWRI]]
rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	qty_packed=num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
	gosub getPickedQty
	gosub getUnpackedQty
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	packed_col=callpoint!.getDevObject("packed_col")
	for row=0 to GridVect!.size()-1
		if qty_packed<unpackedQty then
			packCartonGrid!.setCellFont(row,packed_col,callpoint!.getDevObject("boldFont"))
			packCartonGrid!.setCellForeColor(row,packed_col,callpoint!.getDevObject("redColor"))
		else
			packCartonGrid!.setCellFont(row,packed_col,callpoint!.getDevObject("plainFont"))
			packCartonGrid!.setCellForeColor(row,packed_col,callpoint!.getDevObject("blackColor"))
		endif
	next row

[[OPT_CARTDET2.BEND]]
rem --- Get the total quantity packed
	qtyPacked=0
	dim gridrec$:fattr(rec_data$)
	numrecs=GridVect!.size()
	if numrecs>0 then 
		for reccnt=0 to numrecs-1
			gridrec$=GridVect!.getItem(reccnt)
			qtyPacked=qtyPacked+gridrec.qty_packed
		next reccnt
	endif

rem --- Warn if quantity packed is less than the quantity picked.
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	if qtyPacked<qty_picked
		msg_id$ = "OP_BAD_PACK_QTY"
		dim msg_tokens$[2]
		msg_tokens$[1] = str(qtyPacked)
		msg_tokens$[2] = str(qty_picked)
		gosub disp_message
		if msg_opt$="N"
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[OPT_CARTDET2.BWRI]]
rem --- Make sure CARTON_NO is set to CARTON_DSP
	callpoint!.setColumnData("OPT_CARTDET2.CARTON_NO",callpoint!.getColumnData("<<DISPLAY>>.CARTON_DSP"))

rem --- Initialize RTP modified fields for modified existing records
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())<>"Y" then
		callpoint!.setColumnData("OPT_CARTDET2.MOD_USER", sysinfo.user_id$)
		callpoint!.setColumnData("OPT_CARTDET2.MOD_DATE", date(0:"%Yd%Mz%Dz"))
		callpoint!.setColumnData("OPT_CARTDET2.MOD_TIME", date(0:"%Hz%mz"))
	endif

[[<<DISPLAY>>.CARTON_DSP.AVAL]]
rem --- Need to use <<DISPLAY>> field for CARTON_NO because it is part of the key to the primary table OPT_CARTHDR.
rem --- OPT_CARTDET2 doesn't need to have a primary table because OPT_CARTHDR deletes cascade to OPT_CARTDET.
rem --- However, for maintainability, CARTON_DSP is being used in both OPT_CARTDET and OPT_CARTDET2.

rem --- Initialize new row
	if callpoint!.getGridRowNewStatus(num(callpoint!.getValidationRow()))="Y" then
		carton_no$=callpoint!.getUserInput()
		callpoint!.setColumnData("OPT_CARTDET2.CARTON_NO",carton_no$)
		warehouse_id$=callpoint!.getDevObject("warehouse_id")
		callpoint!.setColumnData("OPT_CARTDET2.warehouse_ID",warehouse_id$,1)
		item_id$=callpoint!.getDevObject("item_id")
		callpoint!.setColumnData("OPT_CARTDET2.ITEM_ID",item_id$,1)
		order_memo$=callpoint!.getDevObject("order_memo")
		callpoint!.setColumnData("OPT_CARTDET2.ORDER_MEMO",order_memo$,1)
		um_sold$=callpoint!.getDevObject("um_sold")
		callpoint!.setColumnData("OPT_CARTDET2.UM_SOLD",um_sold$,1)

		rem --- Refresh Packing & Shipping grid in case a new carton was entered
		callpoint!.setDevObject("refreshRecord",1)

		rem --- The same CARTON_NO cannot be used more than once for the same item.
		optCartDet_dev=fnget_dev("OPT_CARTDET")
		dim optCartDet$:fnget_tpl$("OPT_CARTDET")
		ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
		carton_no$=callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO")
		orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET2.ORDDET_SEQ_REF")
		optCartDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+carton_no$+orddet_seq_ref$
		read(optCartDet_dev,key=optCartDet_trip$,knum="AO_STATUS",dom=*next)
		optCartDet_key$=key(optCartDet_dev,end=*next)
		if pos(optCartDet_trip$=optCartDet_key$)=1 then
			rem --- This item is already packed in this carton
			msg_id$ = "OP_ITEM_IN_CARTON"
			gosub disp_message
			callpoint!.setStatus("ABORT")
			break
		endif
	endif

[[OPT_CARTDET2.QTY_PACKED.AVAL]]
rem --- Disable Pack Lot/Serial button except in qty_packed field
	callpoint!.setOptionEnabled("PKLS",0)

rem --- Skip validation if QTY_PACKED wasn't change
	qty_packed=num(callpoint!.getUserInput())
	previous_qty=num(callpoint!.getColumnData("OPT_CARTDET2.QTY_PACKED"))
	if qty_packed=previous_qty then break

rem --- QTY_PACKED cannot be negative
	if qty_packed<0 then
		msg_id$ = "OP_PACKED_NEGATIVE"
		gosub disp_message
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- QTY_PACKED cannot be greater than the remaining number that still need to be packed.
	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=callpoint!.getDevObject("unpackedQty")
	if qty_packed>unpackedQty then
		msg_id$ = "OP_PACK_REMAINING"
		dim msg_tokens$[3]
		msg_tokens$[1]=str(qty_picked-unpackedQty)
		msg_tokens$[2]=str(qty_picked)
		msg_tokens$[3]=str(unpackedQty)
		gosub disp_message

		callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(previous_qty),1)
		callpoint!.setStatus("ABORT")
		break
	endif

rem --- For lot/serial items, item qty_packed must equal sum of lot/serial number qty_packed for the carton
	ivmItemMast_dev=fnget_dev("IVM_ITEMMAST")
	dim ivmItemMast$:fnget_tpl$("IVM_ITEMMAST")
	item$=callpoint!.getColumnData("OPT_CARTDET2.ITEM_ID")
	findrecord (ivmItemMast_dev,key=firm_id$+item$,dom=*next)ivmItemMast$
	if ivmItemMast.lotser_item$="Y" then
		lotser_packed=0
		optCartLsDet2_dev=fnget_dev("OPT_CARTLSDET2")
		dim optCartLsDet2$:fnget_tpl$("OPT_CARTLSDET2")
		trans_status$=callpoint!.getColumnData("OPT_CARTDET2.TRANS_STATUS")
		ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
		customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
		order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
		ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
		orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET2.ORDDET_SEQ_REF")
		carton_no$=callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO")
		optCartDet2_key$=firm_id$+trans_status$+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$+carton_no$
		read(optCartLsDet2_dev,key=optCartDet2_key$,knum="AO_ORDDET_CART",dom=*next)
		while 1
			optCartLsDet2_key$=key(optCartLsDet2_dev,end=*break)
			if pos(optCartDet2_key$=optCartLsDet2_key$)<>1 then break
			readrecord(optCartLsDet2_dev)optCartLsDet2$
			lotser_packed=lotser_packed+optCartLsDet2.qty_packed
		wend

		if qty_packed<>lotser_packed then
			msg_id$ = "OP_SUM_LOTSER_PACKED"
			dim msg_tokens$[1]
			msg_tokens$[1]=str(lotser_packed)
			gosub disp_message
			callpoint!.setStatus("ABORT")
			callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(lotser_packed),1)
			break
		endif
	endif

rem --- Provide visual warning when quantity packed is less than the remaining number that still need to be packed
	packCartonGrid!=callpoint!.getDevObject("packCartonGrid")
	curr_row=num(callpoint!.getValidationRow())
	packed_col=callpoint!.getDevObject("packed_col")

	if qty_packed<unpackedQty then
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("boldFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("redColor"))
	else
		packCartonGrid!.setCellFont(curr_row,packed_col,callpoint!.getDevObject("plainFont"))
		packCartonGrid!.setCellForeColor(curr_row,packed_col,callpoint!.getDevObject("blackColor"))
	endif

[[OPT_CARTDET2.QTY_PACKED.BINP]]
rem --- For new line, default QTY_PACKED to the remaining number that still need to be packed.
	gosub getUnpackedQty
	if callpoint!.getGridRowNewStatus(callpoint!.getValidationRow())="Y" then
		if callpoint!.getDevObject("lotser_item")="Y" then
			callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(0),1)
		else
			callpoint!.setColumnData("OPT_CARTDET2.QTY_PACKED",str(unpackedQty),1)
		endif
	endif

rem --- Enable Pack Lot/Serial button for lot/serial items
	if callpoint!.getDevObject("lotser_item")="Y" then
		callpoint!.setOptionEnabled("PKLS",1)
	else
		callpoint!.setOptionEnabled("PKLS",0)
	endif

[[OPT_CARTDET2.<CUSTOM>]]
rem ==========================================================================
getPickedQty: rem --- Get quantity picked for this item
               rem      IN: -- none --
               rem   OUT: qty_picked
rem ==========================================================================
	qty_picked=0
	optFillmntDet_dev=fnget_dev("OPT_FILLMNTDET")
	dim optFillmntDet$:fnget_tpl$("OPT_FILLMNTDET")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET2.ORDDET_SEQ_REF")
	optFillmntDet_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optFillmntDet_dev,key=optFillmntDet_trip$,knum="AO_STATUS_ORDDET",dom=*next)
	while 1
		optFillmntDet_key$=key(optFillmntDet_dev,end=*break)
		if pos(optFillmntDet_trip$=optFillmntDet_key$)<>1 then break
		readrecord(optFillmntDet_dev)optFillmntDet$
		qty_picked=optFillmntDet.qty_picked
		break
	wend
	callpoint!.setDevObject("qty_picked",qty_picked)
	read(optFillmntDet_dev,key="",knum="AO_STATUS",dom=*next)

	return

rem ==========================================================================
getUnpackedQty: rem --- Get the remaining quantity that still need to be packed for the given item.
                             rem --- Must count what is packed in all cartons except the current carton
               rem      IN: -- none --
               rem   OUT: unpackedQty
               rem   OUT: qty_picked
rem ==========================================================================
	alreadyPacked=0
	optCartDet2_dev=fnget_dev("OPT_CARTDET2")
	dim optCartDet2$:fnget_tpl$("OPT_CARTDET2")
	ar_type$=callpoint!.getColumnData("OPT_CARTDET2.AR_TYPE")
	customer_id$=callpoint!.getColumnData("OPT_CARTDET2.CUSTOMER_ID")
	order_no$=callpoint!.getColumnData("OPT_CARTDET2.ORDER_NO")
	ar_inv_no$=callpoint!.getColumnData("OPT_CARTDET2.AR_INV_NO")
	orddet_seq_ref$=callpoint!.getColumnData("OPT_CARTDET2.ORDDET_SEQ_REF")
	carton_no$=callpoint!.getColumnData("OPT_CARTDET2.CARTON_NO")
	optCartDet2_trip$=firm_id$+"E"+ar_type$+customer_id$+order_no$+ar_inv_no$+orddet_seq_ref$
	read(optCartDet2_dev,key=optCartDet2_trip$,knum="AO_ORDDET_CART",dom=*next)
	while 1
		optCartDet2_key$=key(optCartDet2_dev,end=*break)
		if pos(optCartDet2_trip$=optCartDet2_key$)<>1 then break
		readrecord(optCartDet2_dev)optCartDet2$
		if optCartDet2.carton_no$=carton_no$ then continue; rem --- Don't count what is in current carton as packed yet.
		alreadyPacked=alreadyPacked+optCartDet2.qty_packed
	wend

	qty_picked=num(callpoint!.getDevObject("qty_picked"))
	unpackedQty=qty_picked-alreadyPacked
	callpoint!.setDevObject("unpackedQty",unpackedQty)

	return

rem ==========================================================================
rem 	Use util object
rem ==========================================================================
	use ::ado_util.src::util




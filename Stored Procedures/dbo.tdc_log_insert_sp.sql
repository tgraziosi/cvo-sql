SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_log_insert_sp] 
	@strUserID 		VARCHAR (50),
	@strTrans_source	VARCHAR (2) = 'VB',
	@strModule		VARCHAR (50),
	@strTrans		VARCHAR (50),
	@strTran_No		VARCHAR (10),
	@strTran_Ext		VARCHAR (5),
	@strPart_No		VARCHAR (30) = '',
	@strLot_Ser		VARCHAR (25) = '',
	@strBin_No		VARCHAR (12) = '',
	@strLocation		VARCHAR (10) = '',
	@strQty			VARCHAR (20) = '',
	@txtData		TEXT = '' ,
	@bitShipVerify		BIT = 0
 AS


IF @bitShipVerify = 1 
	BEGIN
		
		INSERT INTO tdc_log (tran_date, UserID, trans_source, module, trans, tran_no, tran_ext, part_no, 
				    lot_ser, bin_no, location, quantity, data)
		SELECT 	GETDATE() ,			@strUserID , 			
			@strTrans_source, 		@strModule, 			
			@strTrans  ,			@strTran_No,	
			@strTran_Ext,   		tdc_dist_item_pick.part_no,     
			tdc_dist_item_pick.lot_ser ,	tdc_dist_item_pick.bin_no, 
			inv_list.location ,		ABS(tdc_dist_item_pick.quantity), 
			'Carton No = ' + CONVERT(VARCHAR (10),tdc_dist_item_pick.child_serial_no)
		FROM tdc_dist_item_pick (NOLOCK) INNER JOIN
    		     inv_list (NOLOCK) ON 
    		     tdc_dist_item_pick.part_no = inv_list.part_no
		WHERE tdc_dist_item_pick.order_no = @strTran_No 
		AND   tdc_dist_item_pick.order_ext = @strTran_Ext

		


	END

ELSE
	BEGIN
		INSERT INTO tdc_log
			(tran_date , 	UserID , 		trans_source , 	
	 		 module , 	trans , 		tran_no, 
     	 		 tran_ext    , 	part_no, 		lot_ser, 	
	 		 bin_no  , 	location, 		quantity , 
     	 		 data)
		VALUES 
			(getdate(),     @strUserID, 		@strTrans_source,
	 		 @strModule,	@strTrans,		@strTran_No,
   	 		 @strTran_Ext,  @strPart_No, 		@strLot_Ser,	
	 		 @strBin_No,	@strLocation, 		@strQty,
   	 		 @txtData)

	END


RETURN
GO
GRANT EXECUTE ON  [dbo].[tdc_log_insert_sp] TO [public]
GO

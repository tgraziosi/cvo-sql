SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROC [dbo].[tdc_pre_pack_vf_update]
	@con_no 	int,
	@station_id	varchar(3),
	@date		datetime

AS

BEGIN TRAN

	UPDATE tdc_carton_tx                 
	   SET status = 'Q'                  
	  FROM tdc_carton_tx,               
	       #pre_pack_print_sel          
	 WHERE tdc_carton_tx.order_no = #pre_pack_print_sel.order_no    
	   AND tdc_carton_tx.order_ext = #pre_pack_print_sel.order_ext  
	   AND status < 'Q'
                           
	IF @@ERROR != 0 
	BEGIN
		ROLLBACK TRAN
		RAISERROR('update tdc_carton_tx failed', 16, 1)
		RETURN
	END                                               


	UPDATE tdc_carton_detail_tx                 
	   SET status = 'Q'                  
	  FROM tdc_carton_detail_tx,               
	       #pre_pack_print_sel          
	 WHERE tdc_carton_detail_tx.order_no = #pre_pack_print_sel.order_no    
	   AND tdc_carton_detail_tx.order_ext = #pre_pack_print_sel.order_ext  
	   AND status < 'Q'
                           
	IF @@ERROR != 0 
	BEGIN
		ROLLBACK TRAN
		RAISERROR('update tdc_carton_detail_tx failed', 16, 1)
		RETURN
	END    

	UPDATE tdc_main
	   SET virtual_freight  =  'Y'    
	 WHERE consolidation_no = @con_no

	IF @@ERROR != 0 
	BEGIN
		ROLLBACK TRAN
		RAISERROR('update tdc_main_tbl failed', 16, 1)
		RETURN
	END    

            
	IF NOT EXISTS(SELECT * 
		        FROM tdc_vf_queue_tbl (NOLOCK)
                       WHERE consolidation_no =  @con_no)
	BEGIN

		INSERT INTO tdc_vf_queue_tbl (consolidation_no, stage_no, ship_date, code, station_id, priority, 
					      status, vf_packed, outsource)
		VALUES(@con_no, '[ASSIGN]', @date, '[ASSIGN]', @station_id, 1, 'R', 'N', 0)

		IF @@ERROR != 0 
		BEGIN
			ROLLBACK TRAN
			RAISERROR('insert tdc_vf_queue_tbl failed', 16, 1)
			RETURN
		END   
	END
	ELSE
	BEGIN
		UPDATE tdc_vf_queue_tbl  
		   SET ship_date 	= @date
		 WHERE consolidation_no = @con_no

		IF @@ERROR != 0 
		BEGIN
			ROLLBACK TRAN
			RAISERROR('update tdc_vf_queue_tbl failed', 16, 1)
			RETURN
		END    
	END

COMMIT TRAN
RETURN 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pre_pack_vf_update] TO [public]
GO

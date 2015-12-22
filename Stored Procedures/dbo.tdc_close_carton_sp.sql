SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- v1.0 CB 22/03/2012 - CVO-CF-4 Generate Invoice Number at Carton Close
-- v1.1 CT 05/12/2012 - When closing carton for orders like ST or DO, recalculate freight
-- v1.2 CT 26/06/2013 - After recalculating freight, update order totals
-- v1.3 CT 05/11/2013 - Issue #864 - Recalcing drawdown promo credit based on shipped totals
-- v1.4 CT 24/04/2014 - Issue #572 - Deal with multiple orders in the same carton
-- v1.5 CB 12/08/2014 - Issue #1043 - If no frames or suns on the order then set to freight override
-- v1.6 CB 01/09/2014 - Issue #1043 - Need to update both freight values
-- v1.7 CT 05/11/2014 - Issue #1043 - Amendment to v1.5, only do this for ext > 0
  
CREATE PROCEDURE [dbo].[tdc_close_carton_sp]   
@carton_no  INT,  
@station_id varchar(3),   
@userid  varchar(50),  
@cube  int,  
@ErrMsg  VARCHAR(255) OUTPUT  
AS  
  
DECLARE @Status  CHAR(1)   

-- v1.0 Start
DECLARE @doc_ctrl_num	varchar(16),
		@invno			int,
		@result			int,
		@order_no		int,
		@order_ext		int,
		@order_str		VARCHAR(40) -- v1.4
-- v1.0 End

-- START v1.1
DECLARE @order_category VARCHAR(10)
-- END v1.1 

  
IF NOT EXISTS(SELECT * FROM tdc_carton_detail_tx (NOLOCK)  
        WHERE carton_no = @carton_no)  
BEGIN  
 SELECT @ErrMsg = 'Carton has not been packed'  
 RETURN -1  
END  
  
  
SELECT TOP 1 @Status = status FROM tdc_carton_tx  
 WHERE carton_no = @carton_no  
  
IF EXISTS(SELECT * FROM tdc_stage_carton(NOLOCK)  
 WHERE carton_no = @carton_no)  
BEGIN  
 SELECT @ErrMsg = 'Carton already freighted'  
 RETURN -1  
END  
  
IF (@Status NOT IN('O', 'Q') AND ISNULL(@Status,'') <> '')  
BEGIN  
 SELECT @ErrMsg = 'Carton is not open'  
 RETURN -1  
END  
  
BEGIN TRAN  
  
 UPDATE tdc_carton_tx   
     SET status = 'C'  
  WHERE carton_no = @carton_no  
   
 IF @@ERROR <> 0     
 BEGIN  
  ROLLBACK TRAN  
  SELECT @ErrMsg = 'Critical error occured while closing carton'  
  RETURN -1  
 END  
   
 UPDATE tdc_carton_detail_tx   
     SET status = 'C', tx_date = getdate()  
   WHERE carton_no = @carton_no  
  
 IF @@ERROR <> 0     
 BEGIN  
  ROLLBACK TRAN  
  SELECT @ErrMsg = 'Critical error occured while closing carton'  
  RETURN -2  
 END  
 UPDATE tdc_dist_group  
     SET status = 'C'  
   WHERE parent_serial_no = @carton_no  
  
 IF @@ERROR <> 0     
 BEGIN  
  ROLLBACK TRAN  
  SELECT @ErrMsg = 'Critical error occured while closing carton'  
  RETURN -3  
 END  


 -- START v1.4
 -- Loop through all orders in carton
 SET @order_str = ''
 WHILE 1=1
 BEGIN

	SELECT TOP 1
		@order_str = CAST(order_no AS VARCHAR(10)) + '-' + CAST(order_ext AS VARCHAR(3)),
 		@order_no = order_no,
		@order_ext = order_ext
	FROM	
		tdc_carton_tx (NOLOCK)
	WHERE	
		carton_no = @carton_no 
		AND CAST(order_no AS VARCHAR(10)) + '-' + CAST(order_ext AS VARCHAR(3)) > @order_str
	ORDER BY
		CAST(order_no AS VARCHAR(10)) + '-' + CAST(order_ext AS VARCHAR(3))

	IF @@ROWCOUNT = 0
		BREAK
	/*
	 -- START v1.1
	 SELECT	@order_no = order_no,
			@order_ext = order_ext
	 FROM	tdc_carton_tx (NOLOCK)
	 WHERE	carton_no = @carton_no 
	*/
	 SELECT
		@order_category = user_category 
	 FROM
		dbo.orders_all 
	 WHERE
		order_no = @order_no
		AND ext = @order_ext

	-- START v1.7
	IF @order_ext > 0
	BEGIN
	-- END v1.7
		-- v1.5 Start
		IF NOT EXISTS (SELECT 1 FROM ord_list a (NOLOCK) JOIN inv_master b (NOLOCK) ON a.part_no = b.part_no
						WHERE a.order_no = @order_no AND a.order_ext = @order_ext AND b.type_code IN ('FRAME','SUN') AND a.shipped > 0)
		BEGIN
			UPDATE	orders_all
			SET		tot_ord_freight = 0,
					freight = 0, -- v1.6
					freight_allow_type = 'FRTOVRID',
					routing = 'UPSGR'
			WHERE	order_no = @order_no
			AND		ext = @order_ext
		END
		-- v1.5 End
	-- START v1.7
	END
	-- END v1.7

	 IF ISNULL(@order_category,'XX') = 'DO' OR 	LEFT(ISNULL(@order_category,'XX'),2) = 'ST'
	 BEGIN
		EXEC dbo.CVO_GetFreight_recalculate_sp	@order_no, @order_ext, 2
		EXEC fs_updordtots @order_no, @order_ext -- v1.2
	 END
	 -- END v1.1

	-- START v1.3
	EXEC dbo.CVO_debit_promo_update_details_sp @order_no, @order_ext
	-- END v1.3
 END 
 -- END v1.4

 --calculate the freight value for the carton  
 EXEC tdc_calc_carton_value_sp @carton_no  
  
 IF @@ERROR <> 0     
 BEGIN  
  ROLLBACK TRAN  
  SELECT @ErrMsg = 'Critical error occured while closing carton'  
  RETURN -4  
 END  


 -- START v1.4
 SET @order_str = ''
 WHILE 1=1
 BEGIN

	SELECT TOP 1
		@order_str = CAST(order_no AS VARCHAR(10)) + '-' + CAST(order_ext AS VARCHAR(3)),
 		@order_no = order_no,
		@order_ext = order_ext
	FROM	
		tdc_carton_tx (NOLOCK)
	WHERE	
		carton_no = @carton_no 
		AND CAST(order_no AS VARCHAR(10)) + '-' + CAST(order_ext AS VARCHAR(3)) > @order_str
	ORDER BY
		CAST(order_no AS VARCHAR(10)) + '-' + CAST(order_ext AS VARCHAR(3))

	IF @@ROWCOUNT = 0
		BREAK
 
	-- v1.0 Start
	SET @doc_ctrl_num = NULL
	SET @invno = NULL

	SELECT	@doc_ctrl_num = a.doc_ctrl_num,
		@invno = a.inv_number
	FROM	dbo.cvo_order_invoice a (NOLOCK)
	JOIN	tdc_carton_tx b (NOLOCK)
	ON		a.order_no = b.order_no
	AND	a.order_ext = b.order_ext
	WHERE	b.carton_no = @carton_no
	AND	ISNULL(a.inv_number,0) <> 0
	AND a.order_no = @order_no
	AND a.order_ext = @order_ext

	IF ISNULL(@invno,0) = 0
	BEGIN
		EXEC @result = ARGetNextControl_SP 2001, @doc_ctrl_num OUTPUT, @invno OUTPUT, 0  

		IF @doc_ctrl_num IS NOT NULL
		BEGIN
			/*
			SELECT	@order_no = order_no,
					@order_ext = order_ext
			FROM	tdc_carton_tx (NOLOCK)
			WHERE	carton_no = @carton_no
			*/

			DELETE	dbo.cvo_order_invoice
			WHERE	order_no = @order_no
			AND		order_ext = @order_ext

			INSERT	dbo.cvo_order_invoice (order_no, order_ext, inv_number, doc_ctrl_num)
			SELECT	@order_no, @order_ext, @invno, @doc_ctrl_num


		END
		ELSE
		BEGIN
			ROLLBACK TRAN  
			SELECT @ErrMsg = 'An error occured while generating an invoice number!'  
			RETURN -5  
		END
	END
END
 -- v1.0 End
 -- END v1.4

--        If @Cube = 1  
-- BEGIN  
          --  added on 8-13-01 by Trevor Emond for Analysis Services logging  
--          INSERT INTO tdc_ei_performance_log (stationid, userid, trans_source, module, trans, beginning, carton_no, tran_no, tran_ext)                       
--                SELECT @station_id, @userid, 'VB', 'PPS', 'Close Carton', 0, @carton_no, order_no, order_ext   
--    FROM tdc_carton_tx (NOLOCK)   
--   WHERE Carton_No = @Carton_no             
--        End  
  
--If successfull, commit and return 1  
COMMIT TRAN  
RETURN 1  
GO
GRANT EXECUTE ON  [dbo].[tdc_close_carton_sp] TO [public]
GO

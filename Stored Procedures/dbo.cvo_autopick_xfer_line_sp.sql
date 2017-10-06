SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROC [dbo].[cvo_autopick_xfer_line_sp] @tran_id INT,
											@xfer_no INT,
											@qty DECIMAL(20,8)

AS
BEGIN
SET NOCOUNT ON 

-- 10/3/2017 TAG
-- Routine to pick xfers 

DECLARE @qty_to_process DECIMAL(20,8)

CREATE TABLE #temp_who (
	who  varchar(50) not null,  
	login_id varchar(50) not null)  
    
INSERT	#temp_who (who, login_id)   
VALUES	('manager', 'manager')

IF EXISTS (SELECT 1 FROM dbo.tdc_pick_queue AS tpq WHERE tpq.tran_id = @tran_id AND tpq.trans_type_no = @xfer_no)
BEGIN

		IF (SELECT OBJECT_ID('tempdb..#adm_pick_xfer')) IS NOT NULL 
		BEGIN   
			DROP TABLE #adm_pick_xfer
		END

		CREATE TABLE #adm_pick_xfer(xfer_no int not null,line_no int not null,from_loc varchar(10) not null,
		part_no varchar(30) not null,bin_no varchar(12) null,lot_ser varchar(25) null,date_exp datetime null,
		qty decimal(20,8) not null,who varchar(50) not null,err_msg varchar(255) null,row_id int identity not null)

		SELECT @qty_to_process = 0

		SELECT	@qty_to_process = qty_to_process
		FROM	tdc_pick_queue (NOLOCK)
		WHERE	tran_id = @tran_id

		IF @qty > @qty_to_process SELECT @qty = @Qty_to_process -- don't over pick


		INSERT INTO #adm_pick_xfer (xfer_no, line_no, from_loc, part_no, bin_no, lot_ser, date_exp, qty, who) 														 
		SELECT	a.trans_type_no, a.line_no, a.location, a.part_no, a.bin_no, a.lot, b.date_expires, @qty, 'manager'
		FROM	tdc_pick_queue a (NOLOCK)
		JOIN	lot_bin_stock b (NOLOCK)
		ON		a.location = b.location
		AND		a.part_no = b.part_no
		AND		a.bin_no = b.bin_no
		AND		a.lot = b.lot_ser
		WHERE	a.tran_id = @tran_id

		-- for sales orders  EXEC tdc_queue_xfer_ship_pick_sp @tran_id,'','S','0'

		EXEC tdc_queue_xfer_ship_pick_sp @tran_id,'','T','0'


		IF (SELECT OBJECT_ID('tempdb..#adm_pick_xfer')) IS NOT NULL 
		BEGIN   
			DROP TABLE #adm_pick_xfer
		END

		UPDATE tdc_pick_queue SET tx_lock = 'R' WHERE tran_id = @tran_id


END
END

GO
GRANT EXECUTE ON  [dbo].[cvo_autopick_xfer_line_sp] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
/****** Object:  StoredProcedure [dbo].[CVO_unallocate_line_no_sp]    Script Date: 08/18/2010  *****
SED009 -- AutoAllocation    
Object:      Procedure  CVO_unallocate_line_no_sp  
Source file: CVO_unallocate_line_no_sp.sql
Author:		 Jesus Velazquez
Created:	 08/18/2010
Function:    
Modified:    
Calls:    
Called by:   
Copyright:   Epicor Software 2010.  All rights reserved.  
*/
-- v1.0 CB 02/11/2011 - Fix planners workbench issue
CREATE PROCEDURE [dbo].[CVO_unallocate_line_no_sp]
	@order_no		INT,
	@order_ext		INT,
	@location		VARCHAR(10),	
	@needed_part_no	VARCHAR(30),
	@needed_line_no	INT,
	@needed_qty		DECIMAL(20,8),
	@log_info		VARCHAR(100) = '',
	@alloc_from_ebo	INT = 0

AS

BEGIN

DECLARE @lot_ser			VARCHAR(25),
		@bin_no				VARCHAR(12),
		@template_code		VARCHAR(15),    
		@user_id			VARCHAR(50),
		@con_no_passed_in 	INT,		
		@unalloc_qty		DECIMAL(20,8),
		@trans_source		VARCHAR(2)				

SET @template_code		= '[Adhoc]'
SET @user_id			= 'manager'
SET @con_no_passed_in	= 0		

IF (@alloc_from_ebo = 1)
	SET @trans_source = 'BO'
ELSE
	SET @trans_source = 'VB'

		
IF (object_id('tempdb..#plw_alloc_by_lot_bin') IS NOT NULL) 
	DROP TABLE #plw_alloc_by_lot_bin

CREATE TABLE #plw_alloc_by_lot_bin
(lot_ser     VARCHAR(25)   NOT NULL,         
bin_no       VARCHAR(12)   NOT NULL,         
date_expires DATETIME      NOT NULL,         
cur_alloc    DECIMAL(24,8) NOT NULL,         
instock_qty  DECIMAL(24,8)     NULL,         
avail_qty    DECIMAL(24,8) NOT NULL,         
sel_flg1     INT           NOT NULL,         
sel_flg2     INT           NOT NULL,         
qty          DECIMAL(24,8) NOT NULL) 

-- v1.0 - Add where clause
DELETE FROM #so_alloc_management WHERE order_no = @order_no	AND order_ext = @order_ext

SET @unalloc_qty = 0
WHILE @needed_qty > 0
	BEGIN
		--fills #plw_alloc_by_lot_bin with all bins with avail qty for this @part_no
		EXEC tdc_plw_so_allocbylot_init_sp		@location, @needed_part_no, @order_no, @order_ext, @needed_line_no, @needed_qty, @template_code, @user_id

		--get bin_no to unallocate
		SELECT   @lot_ser	= lot_ser,
				 @bin_no	= bin_no,
				 @unalloc_qty	= qty
		FROM     tdc_soft_alloc_tbl (NOLOCK)
		WHERE    order_no	= @order_no		AND 
				 order_ext	= @order_ext	AND 
				 location	= @location		AND
				 line_no    = @needed_line_no		
		ORDER BY qty
		
		IF @unalloc_qty < =  @needed_qty 
			SET @needed_qty = @needed_qty - @unalloc_qty
		ELSE
		BEGIN
			SET @unalloc_qty = @needed_qty
			SET @needed_qty	 = 0
		END

		INSERT INTO tdc_log (tran_date,   UserID,   trans_source, module,        trans,   tran_no,   tran_ext,         part_no,  lot_ser,  bin_no, location ,   quantity,       data) 
		VALUES              (GETDATE(), @user_id,  @trans_source,  'PLW', 'BINGROUPALLOCATION', @order_no, @order_ext, @needed_part_no, @lot_ser, @bin_no, @location, @needed_qty, @log_info)
		
		UPDATE  #plw_alloc_by_lot_bin 
		SET		qty			= @unalloc_qty, 
				sel_flg2	= 1 
		WHERE   lot_ser		= @lot_ser AND
				bin_no		= @bin_no

		EXEC tdc_plw_so_allocbylot_process_sp @location, @needed_part_no, @needed_line_no, @order_no, @order_ext, @user_id, @con_no_passed_in, @template_code		

	END

END

--delete records with zero qty 09/28/10
DELETE FROM tdc_soft_alloc_tbl 
WHERE order_no  = @order_no   AND 
      order_ext = @order_ext  AND
      qty       = 0

GO
GRANT EXECUTE ON  [dbo].[CVO_unallocate_line_no_sp] TO [public]
GO

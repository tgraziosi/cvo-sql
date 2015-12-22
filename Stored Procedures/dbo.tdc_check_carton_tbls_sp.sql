SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

/****** Object:  Stored Procedure dbo.tdc_check_carton_tbls    Script Date: 3/29/99 10:27:59 AM ******/
CREATE PROCEDURE [dbo].[tdc_check_carton_tbls_sp] ( @consol_no int ) 
AS

/* Declare Vars */
	DECLARE @order_no  int,
	 	@order_ext  int,
	 	@carton_no  int


/*Init Var's */

/* Declare cursor for Getting records  */

	DECLARE cursorDstgrp CURSOR FOR SELECT tol.order_no, tol.order_ext,tdg.parent_serial_no 
		                          FROM tdc_cons_ords tol (NOLOCK), tdc_dist_item_pick tdip (NOLOCK), 
					       tdc_dist_group tdg (NOLOCK)
		                         WHERE tol.consolidation_no = @consol_no
		                           AND   tdip.order_no = tol.order_no 
		                           AND   tdip.order_ext = tol.order_ext 
		                           AND   tdg.child_serial_no = tdip.child_serial_no 
		                           AND   tdg.status = 'O'
		                         ORDER BY tdg.parent_serial_no


	OPEN cursorDstgrp

	FETCH NEXT FROM cursorDstgrp INTO @order_no, @order_ext, @carton_no
	WHILE (@@fetch_status = 0) 
	  BEGIN /* next row fetched */
		DELETE FROM  tdc_carton_tx 
		      WHERE order_no   = @order_no
			AND order_ext  = @order_ext
			AND carton_no  = @carton_no
 
		DELETE FROM tdc_carton_detail_tx 
		      WHERE order_no   = @order_no
			AND order_ext  = @order_ext
			AND carton_no  = @carton_no			
		

  	    FETCH NEXT FROM cursorDstgrp INTO @order_no, @order_ext, @carton_no
	  END 	

	CLOSE cursorDstgrp
	DEALLOCATE cursorDstgrp

RETURN 
GO
GRANT EXECUTE ON  [dbo].[tdc_check_carton_tbls_sp] TO [public]
GO

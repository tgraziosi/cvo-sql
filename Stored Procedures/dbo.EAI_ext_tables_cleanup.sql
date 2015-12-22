SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


--  Copyright (c) 2000 Epicor Software, Inc. All Rights Reserved.
CREATE PROCEDURE [dbo].[EAI_ext_tables_cleanup]
	(
	@order_no		int
	)
AS
BEGIN
	--clean up EAI_ext_orders_list, EAI_ext_ordl_kit, EAI_ext_ord_rep

	delete EAI_ext_order_list where order_no = @order_no

	delete EAI_ext_ordl_kit where order_no = @order_no

END
GO
GRANT EXECUTE ON  [dbo].[EAI_ext_tables_cleanup] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- exec wrap_f_calculate_case_sa_qty_sp 1419660, 0, 5796, 'CBCASE6', 'CBBLU2600',2

CREATE PROC [dbo].[wrap_f_calculate_case_sa_qty_sp] @order_no INT,
												@order_ext INT,
												@soft_alloc_no INT,
												@case_part VARCHAR(30),
												@part_no VARCHAR (30),
												@line_no INT
AS
BEGIN


SELECT dbo.f_calculate_case_sa_qty (@order_no,@order_ext,@soft_alloc_no,@case_part,@part_no,@line_no,0,0)

END
GO
GRANT EXECUTE ON  [dbo].[wrap_f_calculate_case_sa_qty_sp] TO [public]
GO

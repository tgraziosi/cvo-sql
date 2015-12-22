SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- =============================================
-- Author:		<Author,,Name>
-- Create date: <Create Date,,>
-- Description:	<Description,,>
-- =============================================
CREATE PROCEDURE [dbo].[Credit_Summary_sp]

@CreditAmount int
AS
BEGIN
	
	SET NOCOUNT ON;
;With C As
(
SELECT order_no,Sum(cr_shipped)AS cr_shipped1,Sum(ExtendedAmt)As ExtendedAmt
FROM cvo_credits_by_Customer_vw
Group By order_no
)

SELECT     cc.territory_code, cc.salesperson_code, cc.customer_code, cc.customer_name,cc.part_no, cc.type_code, cc.pom_date, cc.vendor, cc.cr_shipped, cc.ExtendedAmt,cc.reason,
convert(datetime,dateadd(d,cc.date_shipped-711858,'1/1/1950'),101) AS date_shipped,cc.order_no, cc.order_ext,
dbo.calculate_region_fn(cc.territory_code) as Region
FROM   C left join cvo_credits_by_Customer_vw cc
ON C.order_no = cc.order_no
Where C.ExtendedAmt>@CreditAmount
END
GO

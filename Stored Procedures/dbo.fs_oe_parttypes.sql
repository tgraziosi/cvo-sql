SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_oe_parttypes] @ord_type char(1) = 'I'
AS

Create Table #t_types ( kys char(1),
			description varchar(40) )

Insert #t_types Select 'P', 'Item'
Insert #t_types Select 'M', 'Miscellaneous Item'

if @ord_type = 'I'
begin
Insert #t_types Select 'E', 'Estimate'
Insert #t_types Select 'J', 'Job'
Insert #t_types Select 'V', 'Non-Quantity Bearing Item'
Insert #t_types Select 'X', 'Configurable Item'
Insert #t_types Select 'C', 'Custom Kit'
end
if @ord_type = 'C'
begin
Insert #t_types Select 'A', 'Price Adjustment'
Insert #t_types Select 'N', 'Non-Inventory Return'
Insert #t_types Select 'C', 'Custom Kit'
end

Select kys, description from #t_types
order by kys


GO
GRANT EXECUTE ON  [dbo].[fs_oe_parttypes] TO [public]
GO

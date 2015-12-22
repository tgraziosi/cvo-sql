SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[get_q_custxref] @search varchar(255), @sort char(1), @cust varchar(10), @void char(1)  AS

set rowcount 100

if @sort='C'
begin
  SELECT x.part_no, x.cust_part, i.description
  FROM   dbo.cust_xref x ( NOLOCK ), dbo.inv_master i ( NOLOCK )
  WHERE  x.part_no = i.part_no AND x.customer_key = @cust AND
         x.cust_part >= @search
  ORDER BY x.cust_part, i.part_no
end

if @sort='D'
begin
  SELECT x.part_no, x.cust_part, i.description
  FROM   dbo.cust_xref x ( NOLOCK ), dbo.inv_master i ( NOLOCK )
  WHERE  x.part_no = i.part_no AND x.customer_key = @cust AND
         i.description >= @search
  ORDER BY i.description, x.cust_part, i.part_no
end

if @sort='P'
begin
  SELECT x.part_no, x.cust_part, i.description
  FROM   dbo.cust_xref x ( NOLOCK ), dbo.inv_master i ( NOLOCK )
  WHERE  x.part_no = i.part_no AND x.customer_key = @cust AND
         x.part_no >= @search
  ORDER BY x.part_no, x.cust_part
end
GO
GRANT EXECUTE ON  [dbo].[get_q_custxref] TO [public]
GO

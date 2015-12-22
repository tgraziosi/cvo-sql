SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[get_i_custxref] @search varchar(255), @sort char(1), @cust varchar(10), @void char(1), @username varchar(10)=''  AS

set rowcount 40
declare @cus_con varchar(255) 

select @cus_con=' and ' + isnull((select constrain_by from sec_constraints where kys=@username and table_id='adm_cust_all'),'adm_cust_all.customer_code=adm_cust_all.customer_code')

if @sort='C'
begin
  exec ('SELECT x.part_no, x.cust_part, i.description
  FROM   dbo.cust_xref x, dbo.inv_master i, dbo.adm_cust_all 
  WHERE  x.part_no = i.part_no AND x.customer_code =''+ @cust +
	 '' AND x.cust_part >=''+ @search +
	 '' and x.customer_code=adm_cust_all.customer_code' + @cus_con +
	 ' ORDER BY x.cust_part, i.part_no')
end

if @sort='D'
begin
  exec ('SELECT x.part_no, x.cust_part, i.description
  FROM   dbo.cust_xref x, dbo.inv_master i, dbo.adm_cust_all
  WHERE  x.part_no = i.part_no AND x.customer_code =''+ @cust +
         '' and i.description >=''+ @search +
	 '' and x.customer_code=adm_cust_all.customer_code' + @cus_con +
	 ' ORDER BY i.description, x.cust_part, i.part_no')
end

if @sort='P'
begin
  exec ('SELECT x.part_no, x.cust_part, i.description
  FROM   dbo.cust_xref x, dbo.inv_master i, dbo.adm_cust_all
  WHERE  x.part_no = i.part_no AND x.customer_code =''+ @cust +
         '' AND x.part_no >=''+ @search +
	 '' AND x.customer_code=adm_cust_all.customer_code' + @cus_con +

	 ' ORDER BY x.part_no, x.cust_part')
end

GO
GRANT EXECUTE ON  [dbo].[get_i_custxref] TO [public]
GO

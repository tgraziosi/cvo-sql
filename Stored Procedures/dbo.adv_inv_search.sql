SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS OFF
GO


CREATE PROCEDURE [dbo].[adv_inv_search]
	@part_no  	varchar(30), 	
	@location 	varchar(10), 
	@group 		varchar(10),	
	@vendor 	varchar(12),
	@res_type 	varchar(10), 
	@upc_code	varchar(20),
	@drawing_no	varchar(30),	
	@descr		varchar(255),
	@category_1 	varchar(15),	
	@category_2 	varchar(15), 
	@category_3 	varchar(15),	
	@category_4 	varchar(15),	
	@category_5 	varchar(15),
	@datetime_1	datetime,
	@datetime_2	datetime,
	@long_descr     varchar(100),
	@field_1        varchar(40),
	@field_2        varchar(40),
	@field_3        varchar(40),
	@field_4        varchar(40),
	@field_5        varchar(40),
	@field_6        varchar(40),
	@field_7        varchar(40),
	@field_8        varchar(40),
	@field_9        varchar(40),
	@field_10       varchar(40),
	@field_11       varchar(40),
	@field_12       varchar(40),
	@field_13       varchar(40),
	@field_14       varchar(40),
	@field_15       varchar(40),
	@field_16       varchar(40),
	@from_status 	char(1),
	@to_status 	char(1),
	@qty_greater_0 	char(1),		
	@void 		char(1), 	
	@obsolete 	int, 		
	@web_saleable 	char(1),		
 	@last_part 	varchar(30),
	@non_sellable   char(1) = 'Y',
        @org_id         varchar(30) = '',
        @module		varchar(10) = '',
	@sec_level int = 0

AS

DECLARE @select_clause   varchar(500),
	@from_clause     varchar(100),
	@where_clause    varchar(7300),
	@order_by_clause varchar(20),
	@SQL             varchar(8000),
	@date_field1	 varchar(40),
	@date_field2	 varchar(40),
	@inv_master_add_ind int

IF @datetime_1 IS NULL SET @datetime_1  = ''
ELSE		       SET @date_field1 = CAST(@datetime_1 AS varchar)

IF @datetime_2 IS NULL SET @datetime_2  = ''
ELSE		       SET @date_field2 = CAST(@datetime_2 AS varchar)

set @inv_master_add_ind = 0

if @category_1 != '' or @category_2 != '' or  @category_3 != '' or @category_4 != '' or @category_5 != '' or
 @datetime_1 != '' or @datetime_2 != '' or
 @long_descr != '' or
 @field_1 != '' or @field_2 != '' or @field_3 != '' or @field_4 != '' or @field_5 != '' or @field_6 != '' or
 @field_7 != '' or @field_8 != '' or @field_9 != '' or @field_10 != '' or @field_11 != '' or @field_12 != '' or
 @field_13 != '' or @field_14 != '' or @field_15 != '' or @field_16 != '' 
  set @inv_master_add_ind = 1

-------------------------------------------------------------------------------------
-- Dynamically generate the where clause depending on the passed in parameters
-------------------------------------------------------------------------------------
SET @select_clause   = 					  'SELECT i.part_no,  i.[description], i.category,    i.sku_no,    i.in_stock, i.type_code, 
			       					  i.status,   i.commit_ed,     i.po_on_order, i.available, i.location, 
                                                                  i.uom, 0.0 as ordered,       i.price_a as price'
SET @from_clause     = 					  '  FROM inventory_add  i (NOLOCK) '
SET @where_clause =                                       ' WHERE 1=1 '
IF @part_no      != ''  SET @where_clause = @where_clause + ' AND i.part_no     LIKE ' + CHAR(39) + @part_no     + '%' + CHAR(39)
IF @last_part    != ''  SET @where_clause = @where_clause + ' AND i.part_no     >=   ' + CHAR(39) + @last_part         + CHAR(39)
IF @location     != ''  SET @where_clause = @where_clause + ' AND i.location    LIKE ' + CHAR(39) + @location    + '%' + CHAR(39)
IF @vendor       != ''  SET @where_clause = @where_clause + ' AND i.vendor      LIKE ' + CHAR(39) + @vendor      + '%' + CHAR(39)
IF @group        != ''  SET @where_clause = @where_clause + ' AND i.category    LIKE ' + CHAR(39) + @group       + '%' + CHAR(39)
IF @res_type     != ''  SET @where_clause = @where_clause + ' AND i.type_code   LIKE ' + CHAR(39) + @res_type    + '%' + CHAR(39)
IF @descr        != ''  SET @where_clause = @where_clause + ' AND i.description LIKE ' + CHAR(39) + @descr       + '%' + CHAR(39)
IF @from_status  != ''  SET @where_clause = @where_clause + ' AND i.status      >=   ' + CHAR(39) + @from_status +       CHAR(39)
IF @to_status    != ''  SET @where_clause = @where_clause + ' AND i.status      <=   ' + CHAR(39) + @to_status   +       CHAR(39)
IF @qty_greater_0 = 'Y' SET @where_clause = @where_clause + ' AND i.available   > 0  '
if @inv_master_add_ind = 1
                        SET @where_clause = @where_clause + ' and i.part_no in (select part_no from inv_master_add a (nolock) where 1=1'
IF @category_1   != ''  SET @where_clause = @where_clause + ' AND isnull(a.category_1,'''')  LIKE ' + CHAR(39) + @category_1  + '%' + CHAR(39)
IF @category_2   != ''  SET @where_clause = @where_clause + ' AND isnull(a.category_2,'''')  LIKE ' + CHAR(39) + @category_2  + '%' + CHAR(39)
IF @category_3   != ''  SET @where_clause = @where_clause + ' AND isnull(a.category_3,'''')  LIKE ' + CHAR(39) + @category_3  + '%' + CHAR(39)
IF @category_4   != ''  SET @where_clause = @where_clause + ' AND isnull(a.category_4,'''')  LIKE ' + CHAR(39) + @category_4  + '%' + CHAR(39)
IF @category_5   != ''  SET @where_clause = @where_clause + ' AND isnull(a.category_5,'''')  LIKE ' + CHAR(39) + @category_5  + '%' + CHAR(39)
IF @category_5   != ''  SET @where_clause = @where_clause + ' AND isnull(a.category_5,'''')  LIKE ' + CHAR(39) + @category_5  + '%' + CHAR(39)
IF @datetime_1   != ''  SET @where_clause = @where_clause + ' AND isnull(a.datetime_1,'''')  =    ' + CHAR(39) + @date_field1       + CHAR(39)
IF @datetime_2   != ''  SET @where_clause = @where_clause + ' AND isnull(a.datetime_2,'''')  =    ' + CHAR(39) + @date_field2       + CHAR(39)
IF @long_descr   != ''  SET @where_clause = @where_clause + ' AND isnull(a.long_descr,'''')  LIKE ' + CHAR(39) + '%'+ @long_descr  + '%' + CHAR(39)
IF @field_1      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_1,'''')     LIKE ' + CHAR(39) + @field_1     + '%' + CHAR(39)
IF @field_2      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_2,'''')     LIKE ' + CHAR(39) + @field_2     + '%' + CHAR(39)
IF @field_3      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_3,'''')     LIKE ' + CHAR(39) + @field_3     + '%' + CHAR(39)
IF @field_4      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_4,'''')     LIKE ' + CHAR(39) + @field_4     + '%' + CHAR(39)
IF @field_5      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_5,'''')     LIKE ' + CHAR(39) + @field_5     + '%' + CHAR(39)
IF @field_6      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_6,'''')     LIKE ' + CHAR(39) + @field_6     + '%' + CHAR(39)
IF @field_7      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_7,'''')     LIKE ' + CHAR(39) + @field_7     + '%' + CHAR(39)
IF @field_8      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_8,'''')     LIKE ' + CHAR(39) + @field_8     + '%' + CHAR(39)
IF @field_9      != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_9,'''')     LIKE ' + CHAR(39) + @field_9     + '%' + CHAR(39)
IF @field_10     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_10,'''')    LIKE ' + CHAR(39) + @field_10    + '%' + CHAR(39)
IF @field_11     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_11,'''')    LIKE ' + CHAR(39) + @field_11    + '%' + CHAR(39)
IF @field_12     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_12,'''')    LIKE ' + CHAR(39) + @field_12    + '%' + CHAR(39)
IF @field_13     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_13,'''')    LIKE ' + CHAR(39) + @field_13    + '%' + CHAR(39)
IF @field_14     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_14,'''')    LIKE ' + CHAR(39) + @field_14    + '%' + CHAR(39)
IF @field_15     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_15,'''')    LIKE ' + CHAR(39) + @field_15    + '%' + CHAR(39)
IF @field_16     != ''  SET @where_clause = @where_clause + ' AND isnull(a.field_16,'''')    LIKE ' + CHAR(39) + @field_16    + '%' + CHAR(39)
if @inv_master_add_ind = 1
			SET @where_clause = @where_clause + ')' 
if isnull(@org_id,'') != '' 
			SET @where_clause = @where_clause + ' AND i.location in (select location from dbo.adm_get_related_locs_fn(''' + @module + ''',''' + @org_id + ''',' + convert(varchar,@sec_level) + '))'

			SET @where_clause = @where_clause + ' AND ISNULL(i.obsolete,            0  ) = ' + CAST(@obsolete AS varchar)
			SET @where_clause = @where_clause + ' AND ISNULL(i.void,              ''N'') = ' + CHAR(39) + @void         + CHAR(39)
			SET @where_clause = @where_clause + ' AND ISNULL(i.web_saleable_flag, ''N'') = ' + CHAR(39) + @web_saleable + CHAR(39)
IF(@non_sellable = 'N') SET @where_clause = @where_clause + ' AND NOT EXISTS (SELECT * FROM inv_master (nolock) WHERE part_no = i.part_no AND non_sellable_flag = ''Y'' ) '
SET @order_by_clause = 					  ' ORDER BY i.part_no '
 
SET @SQL = @select_clause + @from_clause + @where_clause + @order_by_clause

SET rowcount 50

EXEC (@SQL)

GO
GRANT EXECUTE ON  [dbo].[adv_inv_search] TO [public]
GO

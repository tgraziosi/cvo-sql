SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE procedure [dbo].[get_inv_loc_add_orders]
	@strsort varchar(50), 	@sort  char(1),     @loc     varchar(10), 
	@void    char(1), 	@stat  char(1),     @type    varchar(10), 
 	@lastkey varchar(30), 	@iobs  int, 	    @vendor  varchar(12),
	@group   varchar(12),	@cat1  varchar(15), @cat2    varchar(15),
	@cat3    varchar(15),	@cat4  varchar(15), @cat5    varchar(15),
	@web     char(1),	@avail int,	    @minstat char(1) ,
	@maxstat char(1)

AS
-- TNS new find inventory by location proc
-- VOID is not used here - should not be able to sell voided parts!!!!

DECLARE @ordered decimal (20,8)

SELECT @ordered = 0.0

SET rowcount 50

IF @sort = 'N'  -- PART NO search
BEGIN 	
	SELECT i.part_no,   i.[description], i.category,   i.sku_no,      i.in_stock, 
	       i.type_code, i.status, 	     i.commit_ed,  i.po_on_order, i.available,
	       i.location,  a.category_1,    a.category_2, i.uom, 	  @ordered as ordered, 
	       i.price_a as price, 'P' as price_type, a.field_2, a.field_3
	 FROM inventory_add  i, 
              inv_master_add a (NOLOCK)
	WHERE (i.part_no  = a.part_no 				)  
	  AND (i.part_no LIKE @strsort  			) 
          AND (i.part_no >= @lastkey				) 
          AND (@loc       ='%' OR i.location = @loc 		) 
          AND (@type      = '%' OR i.type_code LIKE @type 	) 
          AND (status    >= @minstat AND status <= @maxstat 	) 
          AND (obsolete  <= @iobs 				) 
          AND (i.void    != 'V'					) 
          AND (@web       = 'N' OR i.web_saleable_flag LIKE @web) 
          AND (@avail     = 0   OR i.available > 0 		) 
          AND (@vendor    = '%' OR i.vendor     LIKE @vendor 	) 
          AND (@group     = '%' OR i.category   LIKE @group 	) 
          AND (@cat1      = '%' OR a.category_1 LIKE @cat1 	) 
 	  AND (@cat2      = '%' OR a.category_2 LIKE @cat2	) 
          AND (@cat3      = '%' OR a.category_3 LIKE @cat3 	) 
          AND (@cat4      = '%' OR a.category_4 LIKE @cat4	) 
          AND (@cat5      = '%' OR a.category_5 LIKE @cat5 	)
        ORDER BY i.part_no
END
ELSE
BEGIN




























		IF @sort = 'D' -- description
		BEGIN  		
			SELECT  i.part_no, 	i.[description], 	i.category, 	i.sku_no, 		i.in_stock, 
			 	i.type_code, 	i.status, 	i.commit_ed, 	i.po_on_order, 		i.available,
				i.location, 	a.category_1,	a.category_2,	i.uom, 			@ordered as ordered,  
				i.price_a  as price, 'P' as price_type, a.field_2, a.field_3
			FROM inventory_add i, inv_master_add a (NOLOCK)
			WHERE 	( i.part_no = a.part_no ) AND 
				( i.[description] LIKE @strsort ) AND
		 		( i.part_no >= @lastkey ) AND
				( @loc ='%' or  i.location = @loc ) AND 
			 	( @type  = '%' OR i.type_code LIKE @type ) AND
			 	( status >= @minstat AND status <= @maxstat ) AND
			 	( obsolete <= @iobs ) AND 
				( i.void <> 'V') AND
				( @web    = 'N' OR i.web_saleable_flag LIKE @web ) AND
				( @avail  = 0 OR i.available > 0 ) AND
				( @vendor = '%' OR i.vendor LIKE @vendor ) AND
				( @group  = '%' OR i.category LIKE @group ) AND
				( @cat1   = '%' OR a.category_1 LIKE @cat1 ) AND	(@cat2   = '%' OR a.category_2 LIKE @cat2) AND
				( @cat3   = '%' OR a.category_3 LIKE @cat3 ) AND	(@cat4   = '%' OR a.category_4 LIKE @cat4) AND
				( @cat5   = '%' OR a.category_5 LIKE @cat5 )
			 ORDER BY i.part_no		
		END
		ELSE
		BEGIN
			IF @sort = 'L' -- long description
			BEGIN  							
				SELECT  i.part_no, 	i.[description], 	i.category, 	i.sku_no, 		i.in_stock, 
				 	i.type_code, 	i.status, 	i.commit_ed, 	i.po_on_order, 		i.available,
					i.location, 	a.category_1,	a.category_2,	i.uom, 			@ordered as ordered, 
					i.price_a   as price, 'P' as price_type, a.field_2, a.field_3
				FROM inventory_add i, inv_master_add a (NOLOCK)
				WHERE 	( i.part_no = a.part_no ) AND 
					( a.long_descr LIKE @strsort) AND
			 		( i.part_no >= @lastkey ) AND
					( @loc ='%' or  i.location = @loc ) AND 
				 	( @type  = '%' OR i.type_code LIKE @type ) AND
				 	( status >= @minstat AND status <= @maxstat ) AND
				 	( obsolete <= @iobs ) AND 
					( i.void <> 'V') AND
					( @web    = 'N' OR i.web_saleable_flag LIKE @web ) AND
					( @avail  = 0 OR i.available > 0 ) AND
					( @vendor = '%' OR i.vendor LIKE @vendor ) AND
					( @group  = '%' OR i.category LIKE @group ) AND
					( @cat1   = '%' OR a.category_1 LIKE @cat1 ) AND	(@cat2   = '%' OR a.category_2 LIKE @cat2) AND
					( @cat3   = '%' OR a.category_3 LIKE @cat3 ) AND	(@cat4   = '%' OR a.category_4 LIKE @cat4) AND
					( @cat5   = '%' OR a.category_5 LIKE @cat5 )
				ORDER BY i.part_no
			END
			ELSE
			BEGIN























































						IF @sort = 'U' -- UPC code
						BEGIN  
							SELECT  i.part_no, 	i.[description], 	i.category, 	i.sku_no, 		i.in_stock, 
							 	i.type_code, 	i.status, 	i.commit_ed, 	i.po_on_order, 		i.available,
								i.location, 	a.category_1,	a.category_2,	i.uom, 			@ordered as ordered, 
								i.price_a  as price, 'P' as price_type, a.field_2, a.field_3
							FROM inventory_add i, inv_master_add a (NOLOCK)
							WHERE 	( i.part_no = a.part_no ) AND 
								( i.upc_code LIKE @strsort ) AND
						 		( i.part_no >= @lastkey ) AND
								( @loc ='%' or  i.location = @loc ) AND 
							 	( @type  = '%' OR i.type_code LIKE @type ) AND
							 	( status >= @minstat AND status <= @maxstat ) AND
							 	( obsolete <= @iobs ) AND 
								( i.void <> 'V') AND
								( @web    = 'N' OR i.web_saleable_flag LIKE @web ) AND
								( @avail  = 0 OR i.available > 0 ) AND
								( @vendor = '%' OR i.vendor LIKE @vendor ) AND
								( @group  = '%' OR i.category LIKE @group ) AND
								( @cat1   = '%' OR a.category_1 LIKE @cat1 ) AND	(@cat2   = '%' OR a.category_2 LIKE @cat2) AND
								( @cat3   = '%' OR a.category_3 LIKE @cat3 ) AND	(@cat4   = '%' OR a.category_4 LIKE @cat4) AND
								( @cat5   = '%' OR a.category_5 LIKE @cat5 )
								ORDER BY i.part_no,  i.upc_code
						END
						ELSE
						BEGIN
							IF @sort = 'W' -- drawing number
							BEGIN  
								SELECT  i.part_no, 	i.[description], 	i.category, 	i.sku_no, 		i.in_stock, 
								 	i.type_code, 	i.status, 	i.commit_ed, 	i.po_on_order, 		i.available,
									i.location, 	a.category_1,	a.category_2,	i.uom, 			@ordered as ordered	,  
									i.price_a as price	, 'P' as price_type, a.field_2, a.field_3
								FROM inventory_add i, inv_master_add a (NOLOCK)
								WHERE 	( i.part_no = a.part_no ) AND 
									( i.sku_no LIKE @strsort ) AND
							 		( i.part_no >= @lastkey ) AND
									( @loc ='%' or  i.location = @loc ) AND 
								 	( @type  = '%' OR i.type_code LIKE @type ) AND
								 	( status >= @minstat AND status <= @maxstat ) AND
								 	( obsolete <= @iobs ) AND 
									( i.void <> 'V') AND
									( @web    = 'N' OR i.web_saleable_flag LIKE @web ) AND
									( @avail  = 0 OR i.available > 0 ) AND
									( @vendor = '%' OR i.vendor LIKE @vendor ) AND
									( @group  = '%' OR i.category LIKE @group ) AND
									( @cat1   = '%' OR a.category_1 LIKE @cat1 ) AND	(@cat2   = '%' OR a.category_2 LIKE @cat2) AND
									( @cat3   = '%' OR a.category_3 LIKE @cat3 ) AND	(@cat4   = '%' OR a.category_4 LIKE @cat4) AND
									( @cat5   = '%' OR a.category_5 LIKE @cat5 )
									ORDER BY  i.part_no, i.sku_no
							END
							ELSE
							BEGIN
								IF @sort = 'F' -- Fields 1 - 10
								BEGIN  
									SELECT  distinct
										i.part_no, 	i.[description], 	i.category, 	i.sku_no, 		i.in_stock, 
									 	i.type_code, 	i.status, 	i.commit_ed, 	i.po_on_order, 		i.available,
										i.location, 	a.category_1,	a.category_2,	i.uom, 			@ordered as ordered, 
										i.price_a  as price, 'P' as price_type, a.field_2, a.field_3
									FROM inventory_add i, inv_master_add a (NOLOCK), inv_fields f (NOLOCK)
									WHERE 	( i.part_no = a.part_no ) AND i.part_no = f.part_no AND 
										( f.field LIKE @strsort ) AND 
										( i.part_no >= @lastkey) AND
										( @loc ='%' or  i.location = @loc ) AND 
									 	( @type  = '%' OR i.type_code LIKE @type ) AND
									 	( status >= @minstat AND status <= @maxstat ) AND
									 	( obsolete <= @iobs ) AND 
										( i.void <> 'V') AND
										( @web    = 'N' OR i.web_saleable_flag LIKE @web ) AND
										( @avail  = 0 OR i.available > 0 ) AND
										( @vendor = '%' OR i.vendor LIKE @vendor ) AND
										( @group  = '%' OR i.category LIKE @group ) AND
										( @cat1   = '%' OR a.category_1 LIKE @cat1 ) AND	(@cat2   = '%' OR a.category_2 LIKE @cat2) AND
										( @cat3   = '%' OR a.category_3 LIKE @cat3 ) AND	(@cat4   = '%' OR a.category_4 LIKE @cat4) AND
										( @cat5   = '%' OR a.category_5 LIKE @cat5 )
										ORDER BY  i.part_no
									
								END
							END
						END
					--END
				--END
			END
		END
	--END
END




GO
GRANT EXECUTE ON  [dbo].[get_inv_loc_add_orders] TO [public]
GO

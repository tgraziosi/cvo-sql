SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO


CREATE PROCEDURE [dbo].[fs_pricelist_sp]  @item_no varchar (20)   , 
		@type_code varchar (20)  ,
		@group varchar ( 20 )   , 
		@expirationD_cutoff_char varchar ( 20 ) ,  
		@currency_code varchar (15)  

AS













































declare @expirationD_cutoff datetime

select @expirationD_cutoff = convert  ( datetime , @expirationD_cutoff_char)

SELECT distinct  dbo.inv_master.part_no ,   
         dbo.inv_master.description ,   
         dbo.inv_master.category ,   
         dbo.inv_master.type_code ,   
         dbo.inv_master.status ,   
         dbo.part_price.price_a ,   
         dbo.part_price.price_b ,   
         dbo.part_price.price_c ,   
	 dbo.inv_master.void ,   
	Case When ( @expirationD_cutoff is null or @expirationD_cutoff <= dbo.part_price.promo_date_expires ) and
			dbo.part_price.promo_type = 'D'
		then 'Discount, %' 
	         When ( @expirationD_cutoff is null or @expirationD_cutoff <= dbo.part_price.promo_date_expires ) and
			dbo.part_price.promo_type = 'P'
		then 'PRICE' 
	         When ( @expirationD_cutoff is null or @expirationD_cutoff <= dbo.part_price.promo_date_expires ) and
			dbo.part_price.promo_type = 'N'
		then  null 
	          Else null
	End , 
	Case When @expirationD_cutoff is null or @expirationD_cutoff <= dbo.part_price.promo_date_expires
		then dbo.part_price.promo_rate 
	     Else null
	End ,
	Case When @expirationD_cutoff is null or @expirationD_cutoff <= dbo.part_price.promo_date_expires
		then dbo.part_price.promo_date_expires  
	     Else null
	End ,

 	Case When @expirationD_cutoff is null or @expirationD_cutoff <= dbo.part_price.promo_date_expires
		then dbo.part_price.promo_date_entered   
	  Else null
	End ,           
         dbo.inv_master.account ,   
         dbo.part_price.price_d ,   
         dbo.part_price.price_e ,   
         dbo.part_price.price_f ,   
         dbo.part_price.qty_a ,   
         dbo.part_price.qty_b ,   
         dbo.part_price.qty_c,   
         dbo.part_price.qty_d,   
         dbo.part_price.qty_e,   
         dbo.part_price.qty_f
    FROM dbo.inv_master ,   
	dbo.inv_list  ,
	dbo.part_price  
   WHERE 	inv_master.part_no = inv_list.part_no 					and
		( dbo.inv_master.void is null OR dbo.inv_master.void = 'N' ) 			and 
		( @item_no = '%' OR dbo.inv_master.part_no like @item_no )		and 
		( @type_code = '%' OR dbo.inv_master.type_code like @type_code )	and
		(@group = '%' OR dbo.inv_master.category like @group ) 			and
		  dbo.inv_master.part_no = dbo.part_price.part_no 			and
		dbo.part_price.curr_key = @currency_code 
   order by dbo.inv_master.part_no



return 0 

GO
GRANT EXECUTE ON  [dbo].[fs_pricelist_sp] TO [public]
GO

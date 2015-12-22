SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

CREATE proc [dbo].[adord_sp] @WhereClause varchar(255) as
declare
	@OrderBy	varchar(255)

create table #Orders ( 
order_no 	int NOT NULL,
ext      	int NOT NULL,
cust_code  	varchar(10) NULL,
ship_to         varchar(10) NULL, 
ship_to_name 	varchar(40) NULL,
location      	varchar(10) NULL, 
cust_po      	varchar(20) NULL,  
routing      	varchar(20) NULL, 
fob         	varchar(10) NULL,  
attention     	varchar(40) NULL,    
tax_id      	varchar(10) NULL,   
terms    	varchar(10) NULL,  
curr_key     	varchar(10) NULL,  
total_amt_order decimal (20,8) NULL, 
total_tax     	decimal (20,8) NULL,    
total_discount  decimal (20,8) NULL,
freight      	decimal (20,8) NULL, 
total_invoice   decimal (20,8) NULL,   
invoice_no      int NULL,  
doc_ctrl_num    varchar(16) NULL, 
date_invoice    datetime NULL, 
date_entered    datetime NULL, 
date_sch_ship   datetime NULL, 
date_shipped    datetime NULL, 
status          char(1) NULL,
status_desc     varchar(28) NULL,    
who_entered     varchar(20) NULL,    
blanket         char(1) NULL,  
blanket_desc    varchar(3) NULL,  
shipped_flag    varchar(3) NULL,
orig_no         int NULL, 
orig_ext        int NULL,
multiple_ship_to varchar(3) NULL,
Ctel_Order_Num 	varchar(50) NULL,
-- TAG 12/1/2011
user_category   varchar(10) NULL	
)


select @OrderBy = ' order by cust_code ASC, order_no DESC, ext '

exec (' insert #Orders select * from adord_vw ')
exec (' select * from #Orders ' + @WhereClause + @OrderBy)
 


/**/
GO
GRANT EXECUTE ON  [dbo].[adord_sp] TO [public]
GO

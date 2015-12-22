SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO



CREATE PROCEDURE [dbo].[fs_load_list] 
		 @start datetime,       @stop datetime, 
		 @country varchar(40),  @country2 varchar(40),
                 @state varchar(40),   	@state2 varchar(40), 
		 @city varchar(40),     @city2 varchar(40),
                 @zip varchar(10),      @zip2 varchar(10), 
		 @cust varchar(10),     @cust2 varchar(10), 
                 @ord int,              @ord2 int, 
		 @ext int,              @ext2 int, 
		 @rep varchar(10)='%',  @rep2 varchar(10)='%',
		 @terr varchar(10)='%', @terr2 varchar(10)='%',
		 @loc varchar(10)='%',  @stat char(1) 
AS




declare @minstat char(1), @maxstat char(1)

select @minstat = 'P', @maxstat = 'Q'
if @stat = 'N' begin
   select @minstat = 'N'
end

Create Table #tlist (
order_no    int                , order_ext       int,
cust_code   varchar(10)        , sch_ship_date   datetime,
status      char(1)            ,
country     varchar(40) NULL   , state           varchar(40) NULL,
city        varchar(40) NULL   , zip             varchar(40) NULL,
ship_name   varchar(40) NULL   , address1        varchar(40) NULL,
address2    varchar(40) NULL   , address3        varchar(40) NULL,
address4    varchar(40) NULL   , address5        varchar(40) NULL,
cust_name   varchar(40) NULL   , ttemp           char(1),
total_ord   decimal(20,8)      , freight         decimal(20,8),
loc_cnt     integer                                         )


   Insert #tlist
   Select order_no, ext, cust_code, sch_ship_date, status,
          ship_to_country, ship_to_state, ship_to_city, ship_to_zip,
          ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3,
          ship_to_add_4, ship_to_add_5,
          a.customer_name, 'N', total_amt_order, isnull(freight,0), 0
   From orders_all, adm_cust_all a
   Where cust_code = a.customer_code and
         ( @ord = 0 or 
	  (@ord > 0 and ((order_no = @ord and ext >= @ext) or order_no > @ord) -- mls 1/31/02 SCR 28270
            and ((order_no = @ord2 and ext <= @ext2) or order_no < @ord2))) and
         ( sch_ship_date >= @start and sch_ship_date <= @stop ) and
         ( @cust = '%' or (cust_code >= @cust and cust_code <= @cust2) ) and 
         ( @country = '%' or (ship_to_country >= @country and ship_to_country <= @country2) ) and
         ( @state = '%' or (ship_to_state >= @state and ship_to_state <= @state2) ) and 
         ( @city = '%' or (ship_to_city >= @city and ship_to_city <= @city2) ) and
         ( @zip = '%' or (ship_to_zip >= @zip and ship_to_zip <= @zip2) ) and 
         ( @rep = '%' or (salesperson >= @rep and salesperson <= @rep2) ) and 
         ( @terr = '%' or (ship_to_region >= @terr and ship_to_region <= @terr2) ) and 
         ( load_no is null or load_no = 0 ) and
         ( status >= @minstat and status <= @maxstat ) and
         orders_all.type = 'I'

   Update #tlist set loc_cnt = isnull( (select count(*) from ord_list where
                                        ord_list.order_no=#tlist.order_no and
                                        ord_list.order_ext=#tlist.order_ext and
                                        ord_list.location like @loc), 0 )

   Select order_no,  order_ext, cust_code, sch_ship_date, status,
          country,   state,     city,      zip,

          ship_name, address1,  address2,  address3,
          address4,  address5,
          cust_name, 'N',       total_ord, freight,       loc_cnt
   From #tlist
   Where loc_cnt > 0
GO
GRANT EXECUTE ON  [dbo].[fs_load_list] TO [public]
GO

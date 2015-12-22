SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
                                            
                                            
CREATE procedure [dbo].[adm_ins_SO]                                            
@order_no                           int,-- = 0,                                                       
@ext                                int,                                                       
@cust_code                          varchar  (10) = '',                                             
@ship_to                            varchar  (10) = '',                                             
@req_ship_date                      datetime,                                                  
@sch_ship_date                      datetime,                                                  
--@date_shipped                       datetime,                                                  
--@date_entered                       datetime,                                                  
@cust_po                            varchar  (20) = '',                                               
@who_entered                        varchar  (20) = '',                                              
--@status                             char     (1) = 'N',                      
@status                             char     (1) = 'N',                                                
@attention                          varchar  (40) = '',                                               
@phone                              varchar  (20) = '',                                               
@terms                              varchar  (10) = '',                                               
@routing                            varchar  (20) = '',                                               
@special_instr                      varchar  (255),                                              
--@invoice_date                       datetime,                                                  
@total_invoice                      decimal  (13) = 0,--varchar(13) = '0',--decimal  (13) = 0,                                            
@total_amt_order                    decimal  (13) = 0,--decimal  (13) =0,   varchar(13) = '0'                                            
@salesperson                        varchar  (10) = '',                                               
@tax_id                             varchar  (10) = '',                                               
@tax_perc                           decimal  (13) = 0,--decimal  (13) = 0,   varchar(13) = '0'                                            
@invoice_no                         int          = 0,                                             
@fob                                varchar  (10) = '',                                               
@freight                            decimal  (13) = 0,--decimal  (13) = 0,   varchar(13) = '0',                                            
@printed                            char     (1)  = '',                                               
@discount                           decimal (13) = 0, --varchar(13) = '0', --decimal  (13) = 0,    varchar(13) = '0',                                            
@label_no                           int          = 0,                                             
@cancel_date                        datetime ,                                                 
@new                                char     (1)  = '',                                               
@ship_to_name                       varchar  (40) = '',                                               
@ship_to_add_1                      varchar  (40) = '',                                               
@ship_to_add_2                      varchar  (40) = '',                                               
@ship_to_add_3                      varchar  (40) = '',                                               
@ship_to_add_4                      varchar  (40) = '',                                               
@ship_to_add_5                      varchar  (40) = '',                                               
@ship_to_city          varchar  (40) = '',                                               
@ship_to_state                      varchar  (40) = '',            
@ship_to_zip                        varchar  (15) = '',                        
@ship_to_country                    varchar  (40) = '',                                
@ship_to_region                     varchar  (10) = '',                                    
@cash_flag                          char     (1)  = '',                                         
@type                               char     (1)  = '',                                     
@back_ord_flag                      char     (1)  = '',                             
@freight_allow_pct                  decimal  (13) = 0 ,--decimal  (13) = 0 ,    varchar(13) = '0',                                            
@route_code                         varchar  (10) = '',                                               
@route_no                           decimal  (13) =0,                                                
--@date_printed                       datetime ,                                     
--@date_transfered                    datetime ,                                                 
@cr_invoice_no                  int           =0,                                              
@who_picked                         varchar  (20) = '',                                               
@note                               varchar  (255),                                               
@void                   char     (1)  = '',                                               
@void_who                           varchar  (20) = '',                                               
@void_date                          datetime = 0 ,                                             
@changed    char     (1)  = '',                                               
@remit_key                          varchar  (10) = '',                                               
@forwarder_key                    varchar  (10) = '',                                               
@freight_to                         varchar  (10) = '',                                               
@sales_comm                         decimal  (13) = 0 ,--decimal  (13) = 0 ,   varchar  (13) = '0',                                            
@freight_allow_type    varchar  (10) = '',                                               
@cust_dfpa                          char     (1) = '' ,                                               
@location                           varchar  (10)  = '',                                              
@total_tax                          decimal  (13)  = 0, --decimal  (13)  = 0,  varchar  (13) = '0',                                            
@total_discount                     decimal  (13)  = 0, --decimal  (13)  = 0,                                              
@f_note                             varchar  (200) = '',                                              
@invoice_edi                        char     (1)  = '',                                               
@edi_batch                          varchar  (10)  = '',                                              
@post_edi_date                      datetime = 0,                                             
@blanket                            char     (1)  = 'N',                                               
@gross_sales                        varchar  (13) = '0', --decimal  (13) =0,                                                
@load_no                            int      =0,                                             
@curr_key                           varchar  (10) = '',                                               
@curr_type                          char     (1)   = '',                                              
@curr_factor                        decimal  (13) =0, --decimal  (13) =0,    varchar  (13) = '0',                                            
@bill_to_key                        varchar  (10) = '',                                               
@oper_factor                        decimal  (13) =0, --decimal  (13) =0,   varchar  (13) = '0',                                            
@tot_ord_tax                        decimal  (13) =0, --decimal  (13) =0,   varchar  (13) = '0',                                            
@tot_ord_disc                       decimal  (13) =0, --decimal  (13) =0,   varchar  (13) = '0',                                            
@tot_ord_freight                    decimal  (13) =0, --decimal  (13) =0,  varchar  (13) = '0',                                            
@posting_code                       varchar  (10) = '',                                               
@rate_type_home                     varchar  (8)  = '',                                               
@rate_type_oper                     varchar  (8)  = '',                              
@reference_code                     varchar  (32) = '',                                               
@hold_reason                        varchar  (10) = '',                                             
@dest_zone_code                     varchar  (8)  = '',                                               
@orig_no                            int      =0,                                          
@orig_ext                           int      =0,                                             
@tot_tax_incl                       decimal  (13) =0, --decimal  (13) =0,   varchar  (13) = '0',                                            
@process_ctrl_num                   varchar  (32) = '',                                               
@batch_code                         varchar  (16) = '',                                               
@tot_ord_incl                       decimal  (13) =0, --decimal  (13) =0,   varchar  (13) = '0',                                            
@barcode_status                     char     (2)  = '',                                               
@multiple_flag                      char     (1)  = '',                                               
@so_priority_code                   char     (1)  = '',                                               
@FO_order_no                        varchar  (30) = '',                                               
@blanket_amt                        float    =0,                                             
@user_priority                      varchar  (8)  = '',                                               
@user_category                      varchar  (10),                                              
@from_date                          datetime ,                                                 
@to_date                            datetime ,                                                 
@consolidate_flag                   smallint     =0,                                             
@proc_inv_no                        varchar  (32) = '',                                               
@sold_to_addr1                      varchar  (40) = '',                                   
@sold_to_addr2                      varchar  (40) = '',                                               
@sold_to_addr3                      varchar  (40) = '',                                               
@sold_to_addr4                      varchar  (40) = '',                                           
@sold_to_addr5                      varchar  (40) = '',                                               
@sold_to_addr6                      varchar  (40) = '',                                               
@user_code                          varchar  (8)  = '',                                               
@user_def_fld1                      varchar  (255),                                              
@user_def_fld2                      varchar  (255) = '',                                              
@user_def_fld3                      varchar  (255) = '',     
@user_def_fld4                      varchar  (255) ,                                              
@user_def_fld5                      float     =0   ,                                             
@user_def_fld6           float     =0   ,                                             
@user_def_fld7                      float     =0   ,                                         
@user_def_fld8                      float     =0   ,                
@user_def_fld9                      int        =0  ,                                             
@user_def_fld10                     int        =0 ,                                             
@user_def_fld11                     int        =0 ,                                           
@user_def_fld12                     int        ,                                              
@eprocurement_ind                   int        =0 ,                                     
@sold_to                            varchar  (10) = ''  ,                                            
@sopick_ctrl_num                    varchar  (32) = ''  ,                                             
@ship_to_country_cd         varchar  (3)  = ''  ,                                             
@sold_to_city                       varchar  (40) = ''  ,                                             
@sold_to_state                      varchar  (40) = ''  ,                         
@sold_to_zip                        varchar  (15) = ''  ,                                             
@sold_to_country_cd                 varchar  (3)  = ''  ,                                             
@tax_valid_ind                      int       =1   ,                                   
@addr_valid_ind                     int       =1,                                            
@autoship       char(1) = 'N',                                            
@multipleship       char(1) = 'N',                                            
@so_no    varchar(16) OUTPUT                                     
                                            
as                                            
                                            
                                            
declare @ord_no int,  @ord_ext int, @rc int,  @TotAmt money                                            
declare @errorflag int                                            
                                           
declare @customerTEMP  varchar  (10)                                            
declare @dateTEMP datetime                                            
declare @today  int                                            
declare @validFlag char(2)                                            
set @validFlag = '0'                                            
                        
declare @prevStat CHAR(1)                                            
                                            
set @errorflag = 0                                        
                                      
                                            
set @ord_ext=ISNULL(@ext,0)                                            
                                            
--set @cust_code  = @sold_to                                            
                                            
set @TotAmt = 0                                            
                                            
                                
select @ord_no = 0, @rc = 1                                            
                                            
select @location = isnull(@location,'')                                            
if @location != ''                                            
begin                                            
  if not exists (select 1 from locations where location = @location and isnull(void,'N') != 'V' and location not like 'DROP%')                                            
    select @rc = 2, @location = ''                                            
end                                            
if @location = ''                                           
  return -4                                            
                                            
                                            
                                            
                                            
                                            
                           
                                            
                                            
                                            
                                       
                                            
                                            
                                            
             
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                        
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                        
                                            
                                            
                                            
                                            
                                            
                                            
                                            
                                            
select --@phone = contact_phone,                                             
 @ship_to_name = addr1,                                 
 @ship_to_country_cd = country_code,                                            
 @ship_to_add_1 = addr1,                                             
 @ship_to_add_2 = addr2,                                             
 @ship_to_add_3 = addr3,                                             
 @ship_to_add_4 = addr4,                                             
 @ship_to_add_5 = addr5,                                             
 @ship_to_country_cd = country_code,                                            
-- @sold_to_country_cd = country_code,                                            
 @ship_to_zip = postal_code,                                             
 @ship_to_state = state ,                                             
 --@ship_to_country = city           
 @ship_to_city=city,                                           
 @ship_to_country = country                                            
from adm_cust_all                                            
where customer_code = @sold_to                                            
                    
begin                                            
   if @void = 0                                            
                                            
 begin                                            
                                      
                                            
  begin tran                                             
                                              
                                            
    update next_order_num                                            
    set last_no = last_no + 1                                            
    --select @ord_no = last_no from next_order_num                                            
                                              
                                            
--    if ISNULL(@hold_reason, '') = ''                                            
--     set @status = 'N'                                            
--    else                                            
--     set @status = 'A'                           
                                            
                                  
    --Set @so_no = @ord_no      --fzambada USE legacy order numbering                                      
    Set @so_no = @order_no                          
 select @ord_no=@order_no --fzambada                                      
set @cust_po=@user_def_fld1 --fzambada rev3      
                  
--set @ord_no=@ord_no+1                                          
          
    insert orders (                                            
     order_no, ext, cust_code, ship_to, req_ship_date, sch_ship_date, date_shipped, date_entered, cust_po,                                             
         who_entered, status, attention, phone, terms, routing, special_instr, invoice_date, total_invoice,                                             
     total_amt_order, salesperson, tax_id, tax_perc, invoice_no, fob, freight, printed, discount, label_no,                                             
     cancel_date, new, ship_to_name, ship_to_add_1, ship_to_add_2, ship_to_add_3, ship_to_add_4, ship_to_add_5,                                             
     ship_to_city, ship_to_state, ship_to_zip, ship_to_country, ship_to_region, cash_flag, type, back_ord_flag,                                             
     freight_allow_pct, route_code, route_no, date_printed, date_transfered, cr_invoice_no, who_picked, note,                                             
     void, void_who, void_date, changed, remit_key, forwarder_key, freight_to, sales_comm, freight_allow_type,                                             
  cust_dfpa, location, total_tax, total_discount, f_note, invoice_edi, edi_batch, post_edi_date, blanket,                                             
     gross_sales, load_no, curr_key, curr_type, curr_factor, bill_to_key, oper_factor, tot_ord_tax, tot_ord_disc,                                             
     tot_ord_freight, posting_code, rate_type_home, rate_type_oper, reference_code, hold_reason, dest_zone_code,                                             
     orig_no, orig_ext, tot_tax_incl, process_ctrl_num, batch_code, tot_ord_incl, barcode_status, multiple_flag,                                      
     so_priority_code, FO_order_no, blanket_amt, user_priority, user_category, from_date, to_date, consolidate_flag,                                            
     proc_inv_no, sold_to_addr1, sold_to_addr2, sold_to_addr3, sold_to_addr4, sold_to_addr5, sold_to_addr6, user_code,                                            
     ship_to_country_cd, sold_to, sold_to_country_cd ,sold_to_zip, sold_to_state, sold_to_city,user_def_fld4,                                            
      internal_so_ind,organization_id,tax_valid_ind,user_def_fld12 )                                            
    select                                            
     @ord_no, @ord_ext, ISNULL(@sold_to, customer_code), @ship_to,                            
 ISNULL(convert(varchar(20),@req_ship_date, 101),convert(varchar(20),GETDATE(), 101)),                            
 ISNULL(convert(varchar(20),@req_ship_date, 101), convert(varchar(20),GETDATE(), 101)), NULL,         
--convert(varchar(20),GETDATE(), 101), @cancel_date       
--ISNULL(convert(varchar(20),@req_ship_date, 101),convert(varchar(20),GETDATE(), 101)),  --fzambada Rev 2        
ISNULL(convert(varchar(20),@cancel_date, 101),convert(varchar(20),GETDATE(), 101)),  --fzambada Rev 6     
 @cust_po,                                            
         @who_entered,                                
--case when isnull(@blanket, 'N') = 'Y' then 'M' else @status end, --fzambada                                
@status,                                
 @attention, @phone, ISNULL(@terms, terms_code), ISNULL(@routing, ship_via_code), ISNULL(@special_instr,''), NULL, 0,                                            
         --@TotAmt, ISNULL(@salesperson, salesperson_code), ISNULL(@tax_id, tax_code), 0, 0, ISNULL(@fob, fob_code), 0, 'N', 0, 0,                                            
@total_amt_order, ISNULL(@salesperson, salesperson_code), ISNULL(@tax_id, tax_code), 0, 0, ISNULL(@fob, fob_code), 0, 'N', 0, 0,                                                     
NULL, NULL, @ship_to_add_1, @ship_to_add_2, @ship_to_add_3, @ship_to_add_4, @ship_to_add_5, '',--@ship_to_addr6,                                            
--         @ship_to_city, @ship_to_state, @ship_to_zip, ISNULL(@ship_to_country,country), territory_code, 'N', 'I', 0,                                            
@ship_to_city, @ship_to_state, @ship_to_zip, NULL, territory_code, 'N', 'I', 0,                       
         0, route_code, route_no, NULL, NULL, 0, NULL, @note,                                            
         'N', NULL, NULL, 'N', remit_code, forwarder_code, freight_to_code, 0, NULL,                                             
         NULL, @location, 0, 0, NULL, 'N', NULL, NULL, @blanket,                                             
         0,  0, @curr_key, 0, 1, customer_code, 1, 0, 0,                                             
         @freight, ISNULL(@posting_code,posting_code), rate_type_home, rate_type_oper, NULL, ISNULL(@hold_reason,''), dest_zone_code,    --                                            
         0, 0, 0, '','',0,NULL,ISNULL(@multipleship,'N'),                                            
         ISNULL(@so_priority_code, ''), NULL, @blanket_amt, NULL, @user_category, convert(varchar(20),@from_date, 101), convert(varchar(20),@to_date, 101), @consolidate_flag,                                            
         NULL, @sold_to_addr1, @sold_to_addr2, @sold_to_addr3, @sold_to_addr4, @sold_to_addr5, @sold_to_addr6,'NEW',                                            
         @ship_to_country_cd, @cust_code, @sold_to_country_cd ,@sold_to_zip, @sold_to_state, @sold_to_city,@user_def_fld4,0,           
  'CVO',@tax_valid_ind,@user_def_fld12                                
    from adm_cust_all                                            
    where customer_code = @sold_to                                             
                                               
                  
                  
                                            
                                            
                                            
                                            
                                            
               
                                            
    if @@rowcount = 0                                            
    begin                                            
     --return -6                                            
     set @errorflag = 1                                                               
end                                            
                                       
    update o                                            
    set f_note = isnull(name,'') + '                                            
     ' + isnull(addr1,'') + '                                            
     ' + isnull(addr2,'') + '                                            
     ' + isnull(addr3,'')                                             
    from orders o, arfwdr a                         
    where o.order_no = @ord_no and o.ext = @ext and a.kys = o.forwarder_key                                            
    if @@error <> 0                                            
    begin                                              
 set @errorflag = 1                                            
    end                                            
                                              
                                                
                                                
    INSERT INTO ord_rep                                            
    (order_no, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line, order_ext)                  
    SELECT  @ord_no  ,                                            
     temp.salesperson ,                                                           
     temp.sales_comm  ,           
     temp.percent_flag ,                                            
     temp.exclusive_flag ,                                            
     temp.split_flag  ,                                            
     temp.note  ,                                            
     temp.display_line ,                                                
     0                                            
    FROM CVO_TempSOCO temp                                            
    WHERE temp.order_no = @order_no                                               
                       
    if @@error <> 0           
    begin                                             
     set @errorflag = 1                            
    end                                            
                                              
                                                
                                                
                                                
                                            
                                                 
    INSERT INTO ord_payment                                            
 (order_no, trx_desc, date_doc, payment_code, amt_payment,                                             
    amt_disc_taken, doc_ctrl_num, seq_no, order_ext, prompt1_inp,                                             
    prompt2_inp, prompt3_inp, prompt4_inp, cash_acct_code)                           
 SELECT  @ord_no   ,                                             
     temp.trx_desc  ,                                            
     temp.date_doc  ,                                             
     temp.payment_code ,                                             
     temp.amt_payment ,                                             
     temp.amt_disc_taken ,                                             
     temp.doc_ctrl_num ,                                            
     temp.key_table  ,                                            
     0,                                            
     temp.prompt1_inp ,                                            
     temp.prompt2_inp ,                                            
     temp.prompt3_inp ,                                 
     temp.prompt4_inp ,                                            
     temp.cash_acct_code                                            
    FROM CVO_TempSOPAY temp                              
    WHERE temp.order_no = @order_no                                            
                                            
                                            
    if @@error <> 0                                            
    begin                                             
     set @errorflag = 1                                            
    end                                              
                       
                                            
                                            
                                              
                                            
   if @errorflag <> 0                                            
   begin                                            
    rollback tran                                            
    return 100                                            
                                            
   end                                            
                                            
                                            
   set @ext = ISNULL(@ext, 0)                                            
                        
   select @customerTEMP = cust_code, @dateTEMP = date_entered, @prevStat = status                                            
   from orders where order_no = @ord_no and ext = @ext                                             
              
   SET @today = datediff(day, '01/01/1900', @dateTEMP) + 693596                                            
                                            
   --EXEC @validFlag = adm_archklmt_sp @customer_code = @customerTEMP, @date_entered = @today, @ordno = @ord_no, @ordext = @ext                                             
    /*                                              
   if @validFlag = 0                                            
   BEGIN                                            
                                            
    UPDATE orders                                             
    SET status = 'N'                                            
    WHERE order_no = @ord_no                                            
    AND ext = @ext                                            
   END                                            
   ELSE                          
   BEGIN                                   
                                            
    UPDATE orders                                     
    set status = 'C'                                            
    WHERE order_no = @ord_no                                            
    AND ext = @ext                                            
   END                                            
      */                                
                                
insert into cvo_orders_all (order_no,ext,add_case,add_pattern,free_shipping,split_order,flag_print,allocation_date,stage_hold)                                
VALUES (@order_no,@ext,'N','N','N','N',1,ISNULL(convert(varchar(20),@req_ship_date, 101), convert(varchar(20),GETDATE(), 101)),0)                                
        
                                               
  commit tran                                     
                                           
                                            
 end                                             
         
                                            
                                            
                                            
                                            
end                                            
                                            
/**/ 
GO
GRANT EXECUTE ON  [dbo].[adm_ins_SO] TO [public]
GO

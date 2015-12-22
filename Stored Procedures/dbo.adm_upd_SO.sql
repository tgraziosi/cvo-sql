SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO

/*                                                      
               Confidential Information                  
    Limited Distribution of Authorized Persons Only       
    Created 2001 and Protected as Unpublished Work       
          Under the U.S. Copyright Act of 1976            
 Copyright (c) 2001 Epicor Software Corporation, 2001    
                  All Rights Reserved                    
*/                                                









create procedure [dbo].[adm_upd_SO]
@order_no                           int	= 0,          	
@ext                                int = 0,          	
@cust_code                          varchar  (10) = '',	
@ship_to                            varchar  (10) = '',	
@req_ship_date                      datetime,     	
@sch_ship_date                      datetime,     	
--@date_shipped                       datetime,     	
--@date_entered                       datetime,     	
@cust_po                            varchar  (20) = '',  	
@who_entered                        varchar  (20) = '', 	
@status                             char     (1) = '',   	
@attention                          varchar  (40) = '',  	
@phone                              varchar  (20) = '',  	
@terms                              varchar  (10) = '',  	
@routing                            varchar  (20) = '',  	
@special_instr                      varchar  (255) = '', 	
--@invoice_date                       datetime,     	
@total_invoice                      decimal  (13) = 0,--varchar(13) = '0',--decimal  (13) = 0,
@total_amt_order                    decimal  (13) = 0,--decimal  (13) =0,  	varchar(13) = '0'
@salesperson                        varchar  (10) = '',  	
@tax_id                             varchar  (10) = '',  	
@tax_perc                           decimal  (13) = 0,--decimal  (13) = 0,  	varchar(13) = '0'
@invoice_no                         int          = 0,	
@fob                                varchar  (10) = '',  	
@freight                            decimal  (13) = 0,--decimal  (13) = 0,  	varchar(13) = '0',
@printed                            char     (1)  = 'N',  	
@discount                           varchar(13) = '0', --decimal  (13) = 0,   	varchar(13) = '0',
@label_no                           int          = 0,	
@cancel_date                        datetime ,    	
@new                                char     (1)  = '',  	
@ship_to_name                       varchar  (40) = '',  	
@ship_to_add_1                      varchar  (40) = '',  	
@ship_to_add_2                      varchar  (40) = '',  	
@ship_to_add_3                      varchar  (40) = '',  	
@ship_to_add_4                      varchar  (40) = '',  	
@ship_to_add_5                      varchar  (40) = '',  	
@ship_to_city                       varchar  (40) = '',  	
@ship_to_state                      varchar  (40) = '',  	
@ship_to_zip                        varchar  (15) = '',  	
@ship_to_country                    varchar  (40) = '',  	
@ship_to_region                     varchar  (10) = '',  	
@cash_flag                          char     (1)  = '',  	
@type                               char     (1)  = '',  	
@back_ord_flag                      char     (1)  = '',  	
@freight_allow_pct                  decimal  (13) = 0 ,--decimal  (13) = 0 ,  	 varchar(13) = '0',
@route_code                         varchar  (10) = '',  	
@route_no                           decimal  (13) =0,   	
--@date_printed                       datetime ,   	
--@date_transfered                    datetime ,    	
@cr_invoice_no                      int           =0, 	
@who_picked                         varchar  (20) = '',  	
@note                               varchar  (255)= '',  	
@void                               char     (1)  = 'N',  	
@void_who                           varchar  (20) = '',  	
@void_date                          datetime      = 0 ,	
@changed                            char     (1)  = '',  	
@remit_key                          varchar  (10) = '',  	
@forwarder_key                      varchar  (10) = '',  	
@freight_to                         varchar  (10) = '',  	
@sales_comm                         decimal  (13) = 0 ,--decimal  (13) = 0 ,  	varchar  (13) = '0',
@freight_allow_type                 varchar  (10) = '',  	
@cust_dfpa                          char     (1) = '' ,  	
@location                           varchar  (10)  = '', 	
@total_tax                          decimal  (13)  = 0, --decimal  (13)  = 0, 	varchar  (13) = '0',
@total_discount                     decimal  (13)  = 0, --decimal  (13)  = 0, 	
@f_note                             varchar  (200) = '', 	
@invoice_edi                        char     (1)  = '',  	
@edi_batch                          varchar  (10)  = '', 	
@post_edi_date                      datetime     = 0,	
@blanket                            char     (1)  = '',  	
@gross_sales                        varchar  (13) = '0', --decimal  (13) =0,   	
@load_no                            int          =0, 
@curr_key                           varchar  (10) = '',  	
@curr_type                          char     (1)   = '', 	
@curr_factor                        decimal  (13) =0, --decimal  (13) =0,   	varchar  (13) = '0',
@bill_to_key                        varchar  (10) = '',  	
@oper_factor                        decimal  (13) =0, --decimal  (13) =0,  	varchar  (13) = '0',
@tot_ord_tax                        decimal  (13) =0, --decimal  (13) =0,  	varchar  (13) = '0',
@tot_ord_disc                       decimal  (13) =0, --decimal  (13) =0,  	varchar  (13) = '0',
@tot_ord_freight                    decimal  (13) =0, --decimal  (13) =0,  	varchar  (13) = '0',
@posting_code                       varchar  (10) = '',  	
@rate_type_home                     varchar  (8)  = '',  	
@rate_type_oper                     varchar  (8)  = '',  	
@reference_code                     varchar  (32) = '',  	
@hold_reason                        varchar  (10) = '',  	
@dest_zone_code                     varchar  (8)  = '',  	
@orig_no                            int          =0,	
@orig_ext                           int          =0,	
@tot_tax_incl                       decimal  (13) =0, --decimal  (13) =0,  	varchar  (13) = '0',
@process_ctrl_num                   varchar  (32) = '',  	
@batch_code                         varchar  (16) = '',  	
@tot_ord_incl                       decimal  (13) =0, --decimal  (13) =0,  	varchar  (13) = '0',
@barcode_status                     char     (2)  = '',  	
@multiple_flag                      char     (1)  = '',  	
@so_priority_code                   char     (1)  = '',  	
@FO_order_no                        varchar  (30) = '',  	
@blanket_amt                        float        =0,	
@user_priority                      varchar  (8)  = '',  	
@user_category                      varchar  (10)  = '', 	
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
@user_def_fld1                      varchar  (255) = '', 	
@user_def_fld2                      varchar  (255) = '', 	
@user_def_fld3                      varchar  (255) = '', 	
@user_def_fld4                      varchar  (255) = '', 	
@user_def_fld5                      float     =0   ,	
@user_def_fld6                      float     =0   ,	
@user_def_fld7                      float     =0   ,	
@user_def_fld8                      float     =0   ,	
@user_def_fld9                      int        =0  ,	
@user_def_fld10                     int        =0 ,	
@user_def_fld11                     int        =0 , 	
@user_def_fld12                     int        =0 , 	
@eprocurement_ind                   int        =0 , 	
@sold_to                            varchar  (10) = ''  	,
@sopick_ctrl_num                    varchar  (32) = ''  ,	
@ship_to_country_cd                 varchar  (3)  = ''  ,	
@sold_to_city                       varchar  (40) = ''  ,	
@sold_to_state                      varchar  (40) = ''  ,	
@sold_to_zip                        varchar  (15) = ''  ,	
@sold_to_country_cd                 varchar  (3)  = ''  ,	
@tax_valid_ind                      int       =0   ,	
@addr_valid_ind                     int       =0,
@source				    int		=0,
@so_no				varchar(16) OUTPUT   	


as


declare @ord_no int,  @ord_ext int, @rc int,  @TotAmt money

declare @display_line int
set @display_line = 0

set @cust_code  = @sold_to

set @TotAmt = 0


declare @customerTEMP 	varchar  (10)
declare @dateTEMP	datetime
declare @today		int
declare @validFlag	int
set @validFlag = 0

declare @prevStat CHAR(1)




SELECT @prevStat = status from orders where order_no = @order_no and ext = ISNULL(@ext, 0)


begin

if @source = 0
	begin

		begin tran












			
			if @prevStat <> 'C'		
			begin	
				if @hold_reason <> ''
					set @status = 'A'
				else
	
					set @status = 'N'
			end
			else
			begin
				set @status = 'C'
			end





			if @void = 'Y'
			BEGIN
				UPDATE ord_list
				SET 	status = 'V',
					void = 'V'
				where order_no = @order_no

				set @status = 'V'
				set @void = 'V'

			END 

			



















































































































	

			update orders 
			set	
				ship_to				= 	ISNULL(	@ship_to, 	ship_to	),
				req_ship_date			= 	ISNULL(	convert(varchar(20),@req_ship_date, 101) , 	req_ship_date	),
				sch_ship_date			= 	ISNULL(	convert(varchar(20),@sch_ship_date, 101) , 	sch_ship_date	),
				cust_po				= 	ISNULL(	@cust_po,	cust_po	),
				who_entered			= 	ISNULL(	@who_entered, 	who_entered	),			
				status				= 	@status,          
				attention			= 	ISNULL(	@attention, 	attention	),
				phone				= 	ISNULL(	@phone, 	phone	),
				terms				= 	ISNULL(	@terms, 	terms	),
				routing				= 	ISNULL(	@routing, 	routing	),
				special_instr			= 	ISNULL(	@special_instr, 	special_instr	),
				salesperson			= 	ISNULL(	@salesperson, 	salesperson	),
				tax_id				= 	ISNULL(	@tax_id, 	tax_id	),
				fob				= 	ISNULL(	@fob, 	fob	),
				freight				= 	ISNULL(	@freight,	freight	),
				printed				= 	ISNULL(	@printed, 	printed	),
				discount			= 	ISNULL(	@discount, 	discount	),
				ship_to_name			= 	ISNULL(	@ship_to_add_1, 	ship_to_name	),
				ship_to_add_1			= 	ISNULL(	@ship_to_add_2, 	ship_to_add_1	),
				ship_to_add_2			= 	ISNULL(	@ship_to_add_3, 	ship_to_add_2	),
				ship_to_add_3			= 	ISNULL(	@ship_to_add_4, 	ship_to_add_3	),
				ship_to_add_4			= 	ISNULL(	@ship_to_add_5, 	ship_to_add_4	),
				ship_to_city			= 	ISNULL(	@ship_to_city, 	ship_to_city	),
				ship_to_state			= 	ISNULL(	@ship_to_state, 	ship_to_state	),
				ship_to_zip			= 	ISNULL(	@ship_to_zip, 	ship_to_zip	),
				back_ord_flag			= 	ISNULL(	@back_ord_flag,	back_ord_flag	),
				note				= 	ISNULL(	@note,	note	),
				void				= 	ISNULL(	@void, 	void	),
				void_who			= 	ISNULL(	@void_who, 	void_who	),
				void_date			= 	ISNULL(	@void_date, 	void_date	),
				changed				= 	'N', --ISNULL(	'N', 	changed	),
				remit_key			= 	ISNULL(	@remit_key, 	remit_key	),
				forwarder_key			= 	ISNULL(	@forwarder_key, 	forwarder_key	),
				freight_to			= 	ISNULL(	@freight_to, 	freight_to	),
				--sales_comm			= 	ISNULL(	0, 	sales_comm	),
				freight_allow_type		= 	ISNULL(	@freight_allow_type, 	freight_allow_type	),
				location			= 	ISNULL(	@location, 	location	),
				f_note				= 	ISNULL(	@f_note, 	f_note	),
				invoice_edi			= 	ISNULL(	'N', 	invoice_edi	),
				edi_batch			= 	ISNULL(	@edi_batch, 	edi_batch	),
				post_edi_date			= 	ISNULL(	@post_edi_date, 	post_edi_date	),										
				blanket				= 	case when isnull(@ext, 0) > 0 then 'N' else ISNULL(@blanket, 	blanket	) end,
				curr_key			= 	ISNULL(	@curr_key, 	curr_key	),
				curr_type			= 	ISNULL(	@curr_type, 	curr_type	),
				curr_factor			= 	ISNULL(	@curr_factor, 	curr_factor	),
				oper_factor			= 	ISNULL(	@oper_factor, 	oper_factor	),
--				tot_ord_freight			= 	ISNULL(	@freight, 	tot_ord_freight	),
				posting_code			= 	ISNULL(	@posting_code, 	posting_code	),
				rate_type_home			= 	ISNULL(	rate_type_home, 	rate_type_home	),
				rate_type_oper			= 	ISNULL(	rate_type_oper, 	rate_type_oper	),
				reference_code			= 	ISNULL(	@reference_code, 	reference_code	),
				hold_reason			= 	ISNULL(	@hold_reason, 	hold_reason	),
				dest_zone_code			= 	ISNULL(	@dest_zone_code,	dest_zone_code	),
				orig_no				= 	ISNULL(	@orig_no, 	orig_no	),
				orig_ext			= 	ISNULL(	@orig_ext, 	orig_ext	),
				tot_tax_incl			= 	ISNULL(	@tot_tax_incl, 	tot_tax_incl	),
				process_ctrl_num		= 	ISNULL(	@process_ctrl_num,	process_ctrl_num	),
				batch_code			= 	ISNULL(	@batch_code,	batch_code	),
				tot_ord_incl			= 	ISNULL(	@tot_ord_incl,	tot_ord_incl	),
				barcode_status			= 	ISNULL(	@barcode_status,	barcode_status	),
				multiple_flag			= 	ISNULL(	'N',	multiple_flag	),
				so_priority_code		= 	ISNULL(	@so_priority_code, 	so_priority_code	),
				FO_order_no			= 	ISNULL(	@FO_order_no, 	FO_order_no	),
				blanket_amt			= 	ISNULL(	@blanket_amt, 	blanket_amt	),
				user_priority			= 	ISNULL(	@user_priority, 	user_priority	),
				user_category			= 	ISNULL(	@user_category, 	user_category	),
				from_date			= 	ISNULL(	convert(varchar(20),@from_date, 101) , 	from_date	),
				to_date				= 	ISNULL(	convert(varchar(20),@to_date, 101), 	to_date	),
				consolidate_flag		=	ISNULL(	@consolidate_flag,	consolidate_flag	),
				proc_inv_no			= 	ISNULL(	@proc_inv_no, 		proc_inv_no	),
				sold_to_addr1			= 	ISNULL(	@sold_to_addr1, 	sold_to_addr1	),
				sold_to_addr2			= 	ISNULL(	@sold_to_addr2, 	sold_to_addr2	),
				sold_to_addr3			= 	ISNULL(	@sold_to_addr3, 	sold_to_addr3	),
				sold_to_addr4			= 	ISNULL(	@sold_to_addr4, 	sold_to_addr4	),
				sold_to_addr5			= 	ISNULL(	@sold_to_addr5, 	sold_to_addr5	),
				sold_to_addr6			= 	ISNULL(	@sold_to_addr6,	sold_to_addr6	),
				user_code			=	ISNULL(	@user_code,	user_code	),
				ship_to_country_cd		=	ISNULL(	@ship_to_country_cd,	ship_to_country_cd	)
			WHERE order_no = @order_no
			AND ext = ISNULL(@ext, 0)
			

			if @@error <> 0
			begin
				rollback tran
				return 100

			end

			set @so_no = @order_no

		commit tran


		begin tran	

			update o
			set f_note = isnull(name,'') + '
				' + isnull(addr1,'') + '
				' + isnull(addr2,'') + '
				' + isnull(addr3,'') 
			from orders o, arfwdr a
			where o.order_no = @order_no and o.ext = 0 and a.kys = o.forwarder_key


			if @@error <> 0
			begin
				rollback tran
				return 100

			end


		commit tran




		
		if exists (select 1 from ord_rep orp 
					INNER JOIN #TEMPSOCO temp ON orp.order_no = temp.order_no
						AND orp.display_line = temp.display_line  
				 where orp.order_no = @order_no and orp.order_ext = ISNULL(@ext, 0)) 
		BEGIN
			begin tran	
				UPDATE ord_rep 
				SET	ord_rep.order_no   	= ISNULL(#TEMPSOCO.order_no,	ord_rep.order_no)		,
					ord_rep.salesperson  	= ISNULL(#TEMPSOCO.salesperson, ord_rep.salesperson)      	,
					ord_rep.sales_comm      = ISNULL(#TEMPSOCO.sales_comm, ord_rep.sales_comm) 		,
					ord_rep.percent_flag	= ISNULL(#TEMPSOCO.percent_flag, ord_rep.percent_flag)		,
					ord_rep.exclusive_flag	= ISNULL(#TEMPSOCO.exclusive_flag, ord_rep.exclusive_flag)	,
					ord_rep.split_flag	= ISNULL(#TEMPSOCO.split_flag, ord_rep.split_flag)		,
					ord_rep.note		= ISNULL(#TEMPSOCO.note, ord_rep.note)
				FROM #TEMPSOCO 
				WHERE ord_rep.order_no = @order_no and ord_rep.order_ext = ISNULL(@ext, 0)
				and ord_rep.order_no = #TEMPSOCO.order_no 
				and ord_rep.display_line = #TEMPSOCO.display_line				

				

				
	
				if @@error <> 0
				begin
					rollback tran
					return 100	
				end	
			commit tran
		END
		ELSE
		BEGIN

				



				INSERT INTO ord_rep
				(order_no, salesperson, sales_comm, percent_flag, exclusive_flag, split_flag, note, display_line, order_ext)	
				SELECT  @order_no		,
					temp.salesperson	,               
					temp.sales_comm		,
					temp.percent_flag	,
					temp.exclusive_flag	,
					temp.split_flag		,
					temp.note		,
					@display_line		, 			
					ISNULL(@ext, 0)
				FROM #TEMPSOCO temp
				LEFT JOIN ord_rep ord (nolock) ON temp.order_no = ord.order_no
				WHERE temp.order_no = @order_no AND ord.order_no IS NULL 
				AND order_ext = ISNULL(@ext, 0) AND ord.display_line = temp.display_line



			if @@error <> 0
			begin
				rollback tran
				return 100

			end

		END


			if exists (select 1 from ord_payment where order_no = @order_no and order_ext = ISNULL(@ext, 0))
			begin
				begin tran	

				UPDATE ord_payment
				set	ord_payment.trx_desc		=	ISNULL(#TEMPSOPAY.trx_desc,ord_payment.trx_desc),
					ord_payment.date_doc		=	ISNULL(#TEMPSOPAY.date_doc,ord_payment.date_doc),
					ord_payment.payment_code	=	ISNULL(#TEMPSOPAY.payment_code, ord_payment.payment_code),
					ord_payment.amt_payment		=	ISNULL(#TEMPSOPAY.amt_payment, ord_payment.amt_payment),
					ord_payment.prompt1_inp		=	ISNULL(#TEMPSOPAY.prompt1_inp, ord_payment.prompt1_inp),
					ord_payment.prompt2_inp		=	ISNULL(#TEMPSOPAY.prompt2_inp, ord_payment.prompt2_inp),
					ord_payment.prompt3_inp		=	ISNULL(#TEMPSOPAY.prompt3_inp, ord_payment.prompt3_inp),
					ord_payment.prompt4_inp		=	ISNULL(#TEMPSOPAY.prompt4_inp, ord_payment.prompt4_inp),
					ord_payment.amt_disc_taken	=	ISNULL(#TEMPSOPAY.amt_disc_taken,ord_payment.amt_disc_taken),
					ord_payment.cash_acct_code	=	ISNULL(#TEMPSOPAY.cash_acct_code,ord_payment.cash_acct_code),
					ord_payment.doc_ctrl_num	=	ISNULL(#TEMPSOPAY.doc_ctrl_num, ord_payment.doc_ctrl_num)
				from #TEMPSOPAY
				where ord_payment.order_no = #TEMPSOPAY.order_no 
				and ord_payment.order_no = @order_no
				and ord_payment.order_ext = ISNULL(@ext, 0)

				if @@error <> 0
				begin
					rollback tran
					return 100
	
				end

				commit tran
			end
			else
			begin
				begin tran

				INSERT INTO ord_payment
				(order_no, trx_desc, date_doc, payment_code, amt_payment, 
				amt_disc_taken, doc_ctrl_num, seq_no, order_ext, prompt1_inp, 
				prompt2_inp, prompt3_inp, prompt4_inp, cash_acct_code)
				SELECT  @order_no		,	
					temp.trx_desc		,
					temp.date_doc		,	
					temp.payment_code	,	
					temp.amt_payment	,	
					temp.amt_disc_taken	,	
					temp.doc_ctrl_num	,
					temp.key_table		,
					ISNULL(@ext, 0),
					temp.prompt1_inp	,
					temp.prompt2_inp	,
					temp.prompt3_inp	,
					temp.prompt4_inp	,
					temp.cash_acct_code
				FROM #TEMPSOPAY temp
				WHERE temp.order_no = @order_no				

				if @@error <> 0
				begin
					rollback tran
					return 100
				end

				commit tran				

			end


			


			if isnull(@ext, 0) = 0		
				EXEC adm_ins_SO_releases  @order_no	



			update orders
			set status = case when isnull(@blanket, blanket) = 'Y' then 'M' else @status end
			where order_no = @order_no
			and ext = 0


			set @ext = ISNULL(@ext, 0)

			select @customerTEMP = cust_code, @dateTEMP = date_entered from orders where order_no = @order_no and ext = @ext
			SET @today = datediff(day, '01/01/1900', @dateTEMP) + 693596


			EXEC @validFlag = adm_archklmt_sp @customer_code = @customerTEMP, @date_entered = @today, @ordno = @ord_no, @ordext = @ext
			
						
			if ISNULL(@validFlag, 0) = -1
			BEGIN


				UPDATE orders 
				SET status = 'C'
				WHERE order_no = @ord_no
				AND ext = @ext

			END




	end 
	else
	begin


					if @hold_reason = ''
						set @status = 'N'
					else
						set @status = 'A'		

			    	  begin tran
		
					begin
						update orders
						set 	hold_reason = ISNULL(@hold_reason, hold_reason),
							status = @status							
						where order_no = @order_no
						and ext = isnull(@ext, 0)
		
					end
		
					  if @@error <> 0
					  begin
					    rollback tran
					    return -202
					  end
			
				  commit tran	
	end


end

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[adm_upd_SO] TO [public]
GO

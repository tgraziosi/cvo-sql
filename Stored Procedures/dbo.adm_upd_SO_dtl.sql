SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO










create procedure [dbo].[adm_upd_SO_dtl] 

















@ord_no				int = 0, 
@line_no			int = 0,
@part_no			varchar(30) = '', 
@type				char(1) = '',
@ordered			decimal(13) = 0.0, 
@uom				char(2) = '', 
@location			varchar(10) = '', 
@description			varchar(255) = '',
@detailcomment			varchar(255) = '', 
@company			varchar(255) = '',
@account			varchar(32) = '', 
@comm				decimal(13) = 0.0,
@taxcode			varchar(32) = '',
@customer			varchar(10)= '',
@usercount			int = 0,
@createpo			smallint = 0,
@backorderdet			char(1) = '',
@reference_code			varchar(32) = '',  
@Who_entered			varchar(20) = '', 
@soaction			char(1) = '', 
@price				decimal(13) = 0.0, 
@freight			decimal (20,8),
@note				varchar(255) = '',
@source				int,	
@ext				int = 0



as

declare  @ord_ext int, @rc int, @ol_line int, 
  @conv_factor decimal(20,8), @std_uom char(2),
  @kit_ins int,
  @inv_org_id varchar(30),							-- mls 3/24/05
  @masked_gl_rev_acct varchar(32)
declare @chk_sku_ind int
declare @part_type char(1)


--declare @ext int


--select @ext = ext from orders where order_no = @ord_no


---select @ord_no = 0, 
select @rc = 1, @ol_line = 0
select @inv_org_id = isnull((select value_str from config (nolock) where flag = 'INV_ORG_ID'),'')

    if @source = 0
    begin
  	  begin tran

		
			update ord_list
			set
--				order_no	 	=	ISNULL(	@ord_no, 	order_no	),
--				order_ext		=	ISNULL(	0, 	order_ext	),
--				line_no	 		=	ISNULL(	@line_no, 	line_no	),
				location	 	=	ISNULL(	@location, 	location	),
				part_no	 		=	ISNULL(	@part_no, 	part_no	),
				description	 	=	ISNULL(	@description, 	description	),
				time_entered	 	=	ISNULL(	convert(varchar(20),GETDATE(), 101) , 	time_entered	),
				ordered	 		=	ISNULL(	@ordered, 	ordered	),
				shipped	 		=	ISNULL(	0, 	shipped	),
				price	 		= 	ISNULL(	0, 	price	),
				price_type	 	=	ISNULL(	'Y', 	price_type	),
				note	 		=	ISNULL(	@note, 	note	),
				status	 		=	ISNULL(	'N', 	status	),
		--		cost	 		=	ISNULL(	case when i.inv_cost_method = 'S' then i.std_cost else i.avg_cost end, 	cost	),
				who_entered	 	=	ISNULL(	@Who_entered, 	who_entered	),
				sales_comm	 	=	ISNULL(	0, 	sales_comm	),
				temp_price	 	=	ISNULL(	0, 	temp_price	),
				temp_type	 	=	ISNULL(	NULL, 	temp_type	),
				cr_ordered	 	= 	ISNULL(	0, 	cr_ordered	),
				cr_shipped	 	= 	ISNULL(	0, 	cr_shipped	),
				discount	 	= 	ISNULL(	0, 	discount	),
				uom	 		=	ISNULL(	@uom, 	uom	),
				conv_factor	 	=	ISNULL(	@conv_factor, 	conv_factor	),
				void	 		=	ISNULL(	'N', 	void	),
				void_who	 	=	ISNULL(	NULL, 	void_who	),
				void_date	 	=	ISNULL(	NULL, 	void_date	),
				std_cost	 	=	ISNULL(	0, 	std_cost	),
		--		cubic_feet	 	=	ISNULL(	i.cubic_feet, 	cubic_feet	),
				printed	 		= 	ISNULL(	'N', 	printed	),
		--		lb_tracking	 	= 	ISNULL(	i.lb_tracking, 	lb_tracking	),
				labor	 		= 	ISNULL(	0, 	labor	),
		--		direct_dolrs	 	= 	ISNULL(	case when i.inv_cost_method = 'S' then i.std_direct_dolrs else i.avg_direct_dolrs end, 	direct_dolrs	),
		--		ovhd_dolrs	 	=	ISNULL(	case when i.inv_cost_method = 'S' then i.std_ovhd_dolrs else i.avg_ovhd_dolrs end,	ovhd_dolrs	),
		--		util_dolrs	 	=	ISNULL(	case when i.inv_cost_method = 'S' then i.std_util_dolrs else i.avg_util_dolrs end, 	util_dolrs	),
		--		taxable	 		=	ISNULL(	i.taxable, 	taxable	),
		--		weight_ea	 	=	ISNULL(	i.weight_ea, 	weight_ea	),
				qc_flag	 		=	ISNULL(	'N', 	qc_flag	),
				reason_code	 	= 	ISNULL(	NULL, 	reason_code	),
				qc_no	 		=	ISNULL(	0, 	qc_no	),
				rejected	 	=	ISNULL(	0, 	rejected	),
		--		part_type	 	=	ISNULL(	case when i.status = 'V' then 'V' when i.status = 'C' then 'C' else 'P' end, 	part_type	),
				part_type		= 	ISNULL( @part_type, part_type),
		--		orig_part_no	 	=	ISNULL(	i.part_no, 	orig_part_no	),
				back_ord_flag	 	=	ISNULL(	0, 	back_ord_flag	),
				gl_rev_acct	 	=	ISNULL(	@masked_gl_rev_acct, 	gl_rev_acct	),
				total_tax	 	=	ISNULL(	0, 	total_tax	),
		--		tax_code	 	= 	ISNULL(	o.tax_id,	tax_code	),
				curr_price	 	=	ISNULL(	@price, 	curr_price	),
				oper_price	 	=	ISNULL(	0, 	oper_price	),
				display_line	 	=	ISNULL(	@line_no, 	display_line	),
				std_direct_dolrs	=	ISNULL(	0, 	std_direct_dolrs	),
				std_ovhd_dolrs	 	=	ISNULL(	0, 	std_ovhd_dolrs	),
				std_util_dolrs	 	= 	ISNULL(	0, 	std_util_dolrs	),
				reference_code	 	=	ISNULL(	isnull(@reference_code,''), 	reference_code	),
				contract	 	=	ISNULL(	NULL, 	contract	),
				agreement_id	 	=	ISNULL(	NULL, 	agreement_id	),
				ship_to	 		=	ISNULL(	NULL, 	ship_to	),
				service_agreement_flag	=	ISNULL(	'N', 	service_agreement_flag	),
				inv_available_flag	= 	ISNULL(	'Y', 	inv_available_flag	),
				create_po_flag	 	=	ISNULL(	0, 	create_po_flag	),
				load_group_no	 	=	ISNULL(	0, 	load_group_no	),
				return_code	 	=	ISNULL(	NULL, 	return_code	),
				user_count	 	=	ISNULL(	0,	user_count	)
			where order_no = @ord_no 
			and line_no = @line_no
			and order_ext = ISNULL(@ext, 0)

--order_no, order_ext, line_no

	if @@error <> 0
	begin
		rollback tran
		set @rc = -10
		return @rc
	end

	commit tran	

      if exists (select 1 from inv_master where part_no = @part_no and status = 'C')
      begin


	begin tran	
	
	update ord_list_kit
	set
--		order_no	=	ISNULL(	@ord_no, 	order_no	),
--		order_ext	=	ISNULL(	0, 	order_ext	),
--		line_no	 	=	ISNULL(	@line_no, 	line_no	),
		location	=	ISNULL(	@location, 	location	),
		part_no	 	=	ISNULL(	@part_no, 	part_no	),
		part_type	=	ISNULL(	@part_type, 	part_type	),
		ordered	 	=	ISNULL(	@ordered, 	ordered	),
		shipped	 	=	ISNULL(	0, 	shipped	),
		status	 	=	ISNULL(	'N', 	status	),
--		lb_tracking	=	ISNULL(	m.lb_tracking,	lb_tracking	),
		cr_ordered	=	ISNULL(	0, 	cr_ordered	),
		cr_shipped	=	ISNULL(	0, 	cr_shipped	),
		uom	 	=	ISNULL(	@uom, 	uom	),
		conv_factor	=	ISNULL(	1, 	conv_factor	),
		cost	 	=	ISNULL(	0, 	cost	),
		labor	 	=	ISNULL(	0, 	labor	),
		direct_dolrs	=	ISNULL(	0, 	direct_dolrs	),
		ovhd_dolrs	=	ISNULL(	0, 	ovhd_dolrs	),
		util_dolrs	=	ISNULL(	0, 	util_dolrs	),
		note	 	=	ISNULL(	NULL,	note	),
--		qty_per	 	=	ISNULL(	w.qty, 	qty_per	),
		qc_flag	 	=	ISNULL(	'N', 	qc_flag	),
		qc_no	 	=	ISNULL(	0, 	qc_no	),
		description	=	ISNULL(	@description,	description	)
	where order_no = @ord_no
	and line_no = @line_no
	

	if @@error <> 0
	begin
		rollback tran
		set @rc = -10
		return @rc
	end


	commit tran	

      end
    end

return @rc

/**/                                              
GO
GRANT EXECUTE ON  [dbo].[adm_upd_SO_dtl] TO [public]
GO

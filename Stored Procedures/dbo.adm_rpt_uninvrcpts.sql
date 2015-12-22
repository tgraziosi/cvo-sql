SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO


--select period_end_date into :l_period_end from glco (nolock)
--	s_period_end = f_fmt_pltdate (l_period_end)	

create procedure [dbo].[adm_rpt_uninvrcpts] @end_date int = -999, @range varchar(8000) = '0=0' as


BEGIN
if @end_date = -999
  select @end_date = period_end_date from glco (nolock)

declare @sql varchar(8000)
select @range = replace(@range,'"','''')

select @end_date = isnull(@end_date,0)

select @sql = 'SELECT distinct
				 receipts.receipt_no,    
         receipts.vendor,   
         receipts.po_no,   
         receipts.recv_date,   
         receipts.part_no,   
         receipts.quantity,   
         receipts.unit_cost,   
         receipts.location,   
         receipts.unit_measure,   
         receipts.status,   
         pur_list.description,   
         adm_vend_all.vendor_name,   
         receipts.over_flag,   
 	receipts.account_no,
	receipts.tax_included,
	receipts.curr_factor,
	receipts.conv_factor,
	(select min(apply_date) from adm_pomchchg_all h (nolock), adm_pomchcdt d (nolock)
	where h.match_ctrl_int = d.match_ctrl_int and d.receipt_no = receipts.receipt_no and
	h.match_posted_flag != -999) c_apply_date,
	' + convert(varchar(10),@end_date) + ' c_stop,
datalength(rtrim(replace(cast((receipts.unit_cost) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((receipts.unit_cost) as varchar(40))),
datalength(rtrim(replace(cast((receipts.quantity) as varchar(40)),''0'','' ''))) - 
charindex(''.'',cast((receipts.quantity) as varchar(40))),
g.currency_mask,   g.curr_precision, g.rounding_factor, 
case when g.neg_num_format in (0,1,2,10,15) then 1 when g.neg_num_format in (6,7,9,14) then 2 
  when g.neg_num_format in (5,8,11,16) then 3 else 0 end,
case when g.neg_num_format in (2,3,6,9,10,13) then 1 when g.neg_num_format in (4,7,8,11,12,14) then 2 else 3 end,
g.symbol,
case when g.neg_num_format < 9 then '''' when g.neg_num_format in (9,11,14,16) then ''b'' else ''a'' end,
''.'','','',
gl.account_format_mask ,
isnull(receipts.amt_nonrecoverable_tax,0)

    FROM receipts_all receipts (nolock) 
    join adm_vend_all (nolock) on ( receipts.vendor = adm_vend_all.vendor_code )
    left outer join pur_list (nolock) on ( receipts.po_no = pur_list.po_no) and  
         ( receipts.part_no = pur_list.part_no) and ( receipts.po_line = pur_list.line) 
    join glco gl (nolock) on 1=1
    join glcurr_vw g (nolock) on g.currency_code = gl.home_currency 
    join locations l (nolock) on l.location = receipts.location 
    join region_vw r (nolock) on l.organization_id = r.org_id 
   WHERE ( datediff(day,''01/01/1900'',receipts.recv_date) + 693596  <= ' + convert(varchar(10),@end_date) + ' ) and
	( ( receipts.status = ''R'') or (receipts.status = ''S'' and 
	exists (select 1 from adm_pomchchg_all h (nolock), adm_pomchcdt d (nolock)
	where h.match_ctrl_int = d.match_ctrl_int and d.receipt_no = receipts.receipt_no and
	h.match_posted_flag != -999 and 
	datediff(day,''01/01/1900'',apply_date) + 693596 > ' + convert(varchar(10),@end_date) + ') ) ) and 
	( (receipts.part_type = ''M'') or 
	exists (select 1 from inv_master (nolock) where inv_master.part_no = receipts.part_no and 
	inv_master.status = ''V'')) and ' + @range + ' ORDER BY receipts.account_no '

print @sql
exec (@sql)
end   
GO
GRANT EXECUTE ON  [dbo].[adm_rpt_uninvrcpts] TO [public]
GO

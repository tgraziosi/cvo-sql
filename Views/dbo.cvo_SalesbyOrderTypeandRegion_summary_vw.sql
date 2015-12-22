SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE view [dbo].[cvo_SalesbyOrderTypeandRegion_summary_vw]

as
select 
	isnull(cvo.terr_code,'N/A') as Region_code, -- TAG 12/14 - per Finance request
	isnull(cvo.terr_name,'N/A') as Region, 
	cvo.sc_name as SalesConsultant,
	cvo.invoice_date as x_InvoiceDate, 
--	cvo.order_type as OrderType,
--Count(cvo.order_no) as Num_orders,
--Sum(cvo.tot_amt_order) as Amt_orders,
--Sum(cvo.qty_shipped) as Tot_Ship_Qty,
Num_orders_CL = case when cvo.order_type = 'CL' then count(cvo.order_no) else 0 end,
Amt_order_CL = case when cvo.order_type = 'CL' then sum(cvo.tot_amt_order) else 0 end,
Qty_ship_CL = case when cvo.order_type = 'CL' then sum(cvo.qty_shipped) else 0 end,

Num_orders_DO = case when cvo.order_type = 'DO' then count(cvo.order_no) else 0 end,
Amt_order_DO = case when cvo.order_type = 'DO' then sum(cvo.tot_amt_order) else 0 end,
Qty_ship_DO = case when cvo.order_type = 'DO' then sum(cvo.qty_shipped) else 0 end,

Num_orders_RX = case when cvo.order_type = 'RX' then count(cvo.order_no) else 0 end,
Amt_order_RX = case when cvo.order_type = 'RX' then sum(cvo.tot_amt_order) else 0 end,
Qty_ship_RX = case when cvo.order_type = 'RX' then sum(cvo.qty_shipped)else 0 end,

Num_orders_ST = case when cvo.order_type = 'ST' then count(cvo.order_no) else 0 end,
Amt_order_ST = case when cvo.order_type = 'ST' then sum(cvo.tot_amt_order) else 0 end,
Qty_ship_ST = case when cvo.order_type = 'ST' then sum(cvo.qty_shipped) else 0 end,

Num_orders_CR = case when cvo.order_type = 'CR' then count(cvo.order_no) else 0 end,
Amt_order_CR = case when cvo.order_type = 'CR' then sum(cvo.tot_amt_order) else 0 end,
Qty_ship_CR = case when cvo.order_type = 'CR' then sum(cvo.qty_shipped) else 0 end,

Num_orders_Other = case when cvo.order_type not in ('CR','ST','RX','DO','CL') then count(cvo.order_no) else 0 end,
Amt_order_Other = case when cvo.order_type not in ('CR','ST','RX','DO','CL') then sum(cvo.tot_amt_order) else 0 end,
Qty_ship_Other = case when cvo.order_type not in ('CR','ST','RX','DO','CL') then sum(cvo.qty_shipped) else 0 end


from cvo_salesbyordertypeandregion_vw cvo
--where cvo.invoice_date = '7/13/2010'
group by cvo.terr_code, cvo.terr_name, cvo.sc_name, cvo.order_type, cvo.invoice_date
GO
GRANT REFERENCES ON  [dbo].[cvo_SalesbyOrderTypeandRegion_summary_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_SalesbyOrderTypeandRegion_summary_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_SalesbyOrderTypeandRegion_summary_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_SalesbyOrderTypeandRegion_summary_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_SalesbyOrderTypeandRegion_summary_vw] TO [public]
GO

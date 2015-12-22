SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE procedure [dbo].[cvo_customer_anniversary_sp]
as 

-- exec cvo_customer_anniversary_sp

select top 1 customer_code+convert(varchar(10),getdate(),101) as cust_id, customer_code, address_name, dbo.adm_format_pltdate_f(date_opened) date_opened, datepart(m,dbo.adm_format_pltdate_f(date_opened)) month_opened,
contact_name, contact_email from armaster
where (contact_email is not null) and contact_email <> 'info@cvoptical.com'
and contact_email like '%@%'
and status_type = 1
and address_type <> 9
and addr_sort1 <> 'Buying Group'
and  datepart(m,dbo.adm_format_pltdate_f(date_opened)) = datepart(m,getdate())
and datepart(yy,dbo.adm_format_pltdate_f(date_opened)) <> datepart(yy,getdate())

GO
GRANT EXECUTE ON  [dbo].[cvo_customer_anniversary_sp] TO [public]
GO

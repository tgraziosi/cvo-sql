SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
create view [dbo].[cvo_sc_report_schedule_vw] 
as 
select distinct x.territory_code, x.salesperson_code, x.user_name, x.security_code, x.email_address, slp.salesperson_type from cvo_territoryxref x
left outer join arsalesp slp on x.territory_code = slp.territory_code
where (x.salesperson_code not in ('internal','ss'))
and slp.status_type = 1
GO
GRANT REFERENCES ON  [dbo].[cvo_sc_report_schedule_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[cvo_sc_report_schedule_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[cvo_sc_report_schedule_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[cvo_sc_report_schedule_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[cvo_sc_report_schedule_vw] TO [public]
GO

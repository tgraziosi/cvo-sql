SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_sc_report_schedule_vw]
AS
    SELECT DISTINCT
            x.territory_code ,
            x.Salesperson_code ,
            x.User_name ,
            x.security_code ,
            x.email_address ,
            slp.salesperson_type
    FROM    CVO_TerritoryXref x
            JOIN arsalesp slp ON x.territory_code = slp.territory_code
    WHERE   ( x.Salesperson_code NOT IN ( 'internal', 'ss' ) )
            AND 1 = ISNULL(slp.status_type,0)
			AND x.Status = 1 ;

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

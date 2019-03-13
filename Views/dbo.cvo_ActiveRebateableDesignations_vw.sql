SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE VIEW [dbo].[cvo_ActiveRebateableDesignations_vw]
AS

--select * FRom cvo_activerebateabledesignations_vw

SELECT DISTINCT 
    ar.territory_code,
    ar.customer_code,
    ar.address_name,
    ar.addr2,
    CASE
        WHEN ar.addr3 LIKE '%, __ %' THEN
            ''
        ELSE
            ar.addr3
    END AS addr3,
    city,
    state,
    postal_code AS Zip,
    country_code AS CC,
	ar.contact_email,
    ar.price_code price_class, -- 042015 - LF request
	ISNULL(Pri_desig.desig,'') Primary_Designation,
	ISNULL(REPLACE (STUFF(( SELECT  '; ' + dc.description
                                    FROM    cvo_cust_designation_codes (NOLOCK) cd
									JOIN dbo.cvo_designation_codes dc on dc.rebate = 'Y' AND dc.code = cd.code
									WHERE   cd.customer_code = ar.customer_code
                                            AND ISNULL(cd.start_date, GETDATE()) <= getdate()
                                            AND ISNULL(cd.end_date, getdate()) >= getdate()									
											AND cd.primary_flag <> 1 AND dc.rebate = 'Y'
                                    FOR
                                    XML PATH('')
                                    ), 1, 1, '')
                                    ,'&amp;','&'), '') Active_Rebateable_Designations,
	getdate() asofdate

FROM dbo.armaster AS ar

LEFT OUTER JOIN 
( SELECT distinct   RIGHT(cd.customer_code, 5) MergeCust , dc2.description desig
                    FROM    cvo_cust_designation_codes (NOLOCK) cd
					JOIN dbo.cvo_designation_codes AS dc2 ON dc2.code = cd.code
									WHERE   cd.primary_flag = 1 
											AND ISNULL(cd.start_date, GETDATE()) <= getdate()
                                            AND ISNULL(cd.end_date, getdate()) >= getdate()
											
                ) AS Pri_desig ON Pri_desig.MergeCust = RIGHT(ar.customer_code,5)

WHERE (ar.address_type = 0) 
-- ORDER BY ar.customer_code
;





GO
GRANT SELECT ON  [dbo].[cvo_ActiveRebateableDesignations_vw] TO [public]
GO

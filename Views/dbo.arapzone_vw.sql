SET QUOTED_IDENTIFIER OFF
GO
SET ANSI_NULLS ON
GO
CREATE VIEW [dbo].[arapzone_vw] AS SELECT zone_code, zone_desc FROM arzone UNION SELECT zone_code, zone_desc FROM apzone
GO
GRANT REFERENCES ON  [dbo].[arapzone_vw] TO [public]
GO
GRANT SELECT ON  [dbo].[arapzone_vw] TO [public]
GO
GRANT INSERT ON  [dbo].[arapzone_vw] TO [public]
GO
GRANT DELETE ON  [dbo].[arapzone_vw] TO [public]
GO
GRANT UPDATE ON  [dbo].[arapzone_vw] TO [public]
GO

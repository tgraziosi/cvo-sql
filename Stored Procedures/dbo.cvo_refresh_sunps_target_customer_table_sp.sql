SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
-- for RL
CREATE PROCEDURE [dbo].[cvo_refresh_sunps_target_customer_table_sp]
AS 
BEGIN

TRUNCATE TABLE dbo.cvo_programs_target_customers

INSERT INTO cvo_programs_target_customers (
                  Status,
                  Terr,
                  customer_code,
                  ship_to_code,
                  PROMO_level,
                  address_name,
                  addr2,
                  addr3,
                  city,
                  state,
                  postal_code,
                  country_code,
                  contact_phone,
                  tlx_twx,
                  contact_email,
                  period,
                  Inv_cnt,
                  Inv_qty
                  )

EXEC dbo.cvo_sunps_tracker_sp @asofdate = NULL,
                          @sdate = NULL,
                          @edate = NULL,
                          @debug = 0                 
        
 END
GO
GRANT EXECUTE ON  [dbo].[cvo_refresh_sunps_target_customer_table_sp] TO [public]
GO

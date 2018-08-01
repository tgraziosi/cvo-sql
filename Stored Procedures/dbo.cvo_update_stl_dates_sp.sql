SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_update_stl_dates_sp]
    @fromdate DATETIME,
    @todate DATETIME = NULL
AS
BEGIN

    SET NOCOUNT ON;

    DECLARE @olddate INT,
            @newdate INT;
    --SELECT @olddate = dbo.adm_get_pltdate_f('08/01/2018') 
    --SELECT @newdate = dbo.adm_get_pltdate_f('07/31/2018')

    SELECT @olddate = dbo.adm_get_pltdate_f(@fromdate);
    SELECT @newdate = dbo.adm_get_pltdate_f(@todate);

    --select dbo.adm_get_pltdate_f('12/01/2016') -- 735967
    --select dbo.adm_get_pltdate_f('07/29/2016') -- 735963

    SELECT settlement_ctrl_num,
           description,
           hold_flag,
           posted_flag,
           dbo.adm_format_pltdate_f(date_entered) date_entered,
           dbo.adm_format_pltdate_f(date_applied) date_applied,
           sv.user_name user_id,
           doc_sum_expected,
           customer_code
    FROM arinpstlhdr
	LEFT OUTER JOIN dbo.smusers_vw AS sv ON sv.user_id = arinpstlhdr.user_id
    WHERE date_applied = @olddate;

    IF @todate IS NOT NULL
    BEGIN

        UPDATE dbo.arinppyt
        SET date_applied = @newdate
        -- select * from arinppyt 
        WHERE date_entered = @olddate
              AND date_applied = @olddate;

        UPDATE dbo.arinpstlhdr
        SET date_applied = @newdate
        -- select * from arinpstlhdr 
        WHERE date_entered = @olddate
              AND date_applied = @olddate;
    END;
END;

GRANT EXECUTE ON dbo.cvo_update_stl_dates_sp TO PUBLIC;
GO
GRANT EXECUTE ON  [dbo].[cvo_update_stl_dates_sp] TO [public]
GO

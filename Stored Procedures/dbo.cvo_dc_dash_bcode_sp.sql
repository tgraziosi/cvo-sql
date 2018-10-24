SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_bcode_sp] @asofdate DATETIME = NULL
AS
BEGIN

    IF @asofdate IS NULL
        SELECT @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

    SELECT ISNULL(fname + ' ' + lname, bl.bcode_user) username,
           COUNT(upc) num_trans
    FROM dbo.cvo_bcode_log AS bl
        LEFT OUTER JOIN cvo_cmi_users cu
            ON cu.user_login = bl.bcode_user
    WHERE bl.isPrinted = 1
          AND bl.bcode_date >= @asofdate
    GROUP BY ISNULL(fname + ' ' + lname, bl.bcode_user);

END;

GRANT EXECUTE ON dbo.cvo_dc_dash_bcode_sp TO PUBLIC;
GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_bcode_sp] TO [public]
GO

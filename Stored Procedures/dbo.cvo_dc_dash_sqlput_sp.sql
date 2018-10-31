SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_sqlput_sp] @asofdate DATETIME = NULL
AS
BEGIN

    IF @asofdate IS NULL
        SELECT @asofdate = DATEADD(dd, DATEDIFF(dd, 0, GETDATE()), 0);

    SELECT 'SGLPUTAWAY' QSTATUS,
           'STARTING BALANCE' USERNAME,
           SUM(qty) TOT_QTY
    FROM lot_bin_stock LB
    WHERE location = '001'
          AND bin_no = 'RR PUTAWAY'
    UNION ALL
    SELECT 'SGLPUTAWAY' QSTATUS,
           ISNULL(u.fname + ' ' + u.lname, T.UserID) username,
           COUNT(T.tran_no) num_trans
    FROM tdc_log T (NOLOCK)
        LEFT OUTER JOIN cvo_cmi_users u (NOLOCK)
            ON u.user_login = REPLACE(T.UserID, 'cvoptical\', '')
    WHERE T.trans = 'bn2bn'
          AND T.bin_no = 'rr putaway'
          AND T.trans_source = 'CO'
          AND T.tran_date >= @asofdate
    GROUP BY ISNULL(u.fname + ' ' + u.lname, T.UserID)
    UNION ALL
        SELECT 'SGLPUTAWAY' QSTATUS,
           ISNULL(u.fname + ' ' + u.lname, T.sp_user) username,
           COUNT(T.id) num_trans
    FROM dbo.cvo_single_piece_log AS T (NOLOCK)
        LEFT OUTER JOIN cvo_cmi_users u (NOLOCK)
            ON u.user_login = REPLACE(T.sp_user, 'cvoptical\', '')
    WHERE T.addtime >= @asofdate
    GROUP BY ISNULL(u.fname + ' ' + u.lname, T.sp_user);

END;

GRANT EXECUTE ON dbo.cvo_dc_dash_sqlput_sp TO PUBLIC;
GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_sqlput_sp] TO [public]
GO

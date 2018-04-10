SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_filter_credits_sp] @YN CHAR(1)
AS

-- EXEC CVO_FILTER_CREDITS_SP 'Y'

BEGIN


    UPDATE c
    SET value_str = UPPER(@YN)
	FROM CONFIG C
    WHERE FLAG = 'CVO_FILTER_CREDITS'
          AND VALUE_STR <> @YN;

    SELECT flag,
           description,
           value_str
    FROM config
    WHERE flag = 'cvo_filter_credits';

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_filter_credits_sp] TO [public]
GO

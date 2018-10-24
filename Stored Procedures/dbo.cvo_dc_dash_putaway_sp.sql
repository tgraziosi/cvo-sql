SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO
CREATE PROCEDURE [dbo].[cvo_dc_dash_putaway_sp]
AS
BEGIN

    SELECT ISNULL(b.group_code, 'UnDirected') Group_code,
           COUNT(put.tran_id) num_puts
    FROM tdc_put_queue put (NOLOCK)
        LEFT OUTER JOIN tdc_bin_master b (NOLOCK)
            ON b.bin_no = put.next_op
               AND b.location = put.location
    WHERE put.trans = 'poptwy'
    GROUP BY ISNULL(b.group_code, 'UnDirected');

END;

GO
GRANT EXECUTE ON  [dbo].[cvo_dc_dash_putaway_sp] TO [public]
GO

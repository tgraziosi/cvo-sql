SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_q_set_mgt_lock_sp] (
@QueueTable Varchar(30),
@Tran_ID int, 
@Lock int)
AS
/**************************************************************************
tdc_q_reprioritize_sp - This stored procedure is used to.
Parameters:
    @QueueTable - 
    @Tran_ID - 
    @Lock - 

12/2/1999    Initial        Samuel Eniojukan
***************************************************************************/

IF @QueueTable = 'tdc_pick_queue'
BEGIN
IF @Lock = 0
  BEGIN
    IF NOT EXISTS(SELECT NULL FROM tdc_pick_queue WHERE tx_lock IN ('M', 'N') AND tran_id = @tran_id)
        return -1
    UPDATE tdc_pick_queue 
    SET tx_lock = CASE tx_lock
                    WHEN 'M' THEN 'H'
                    WHEN 'N' THEN 'R'
                  END
    WHERE tran_id = @tran_id
    return 0
  END
ELSE
  BEGIN
    IF NOT EXISTS(SELECT NULL FROM tdc_pick_queue WHERE tx_lock IN ('H', 'R') AND tran_id = @tran_id)
        return -1
    UPDATE tdc_pick_queue 
    SET tx_lock = CASE tx_lock
                    WHEN 'H' THEN 'M'
                    WHEN 'R' THEN 'N'
                  END
    WHERE tran_id = @tran_id
    return 0
  END
END

IF @QueueTable = 'tdc_put_queue'
BEGIN
IF @Lock = 0
  BEGIN
    IF NOT EXISTS(SELECT NULL FROM tdc_put_queue WHERE tx_lock IN ('M', 'N') AND tran_id = @tran_id)
        return -1
    UPDATE tdc_put_queue 
    SET tx_lock = CASE tx_lock
                    WHEN 'M' THEN 'H'
                    WHEN 'N' THEN 'R'
                  END
    WHERE tran_id = @tran_id
    return 0
  END
ELSE
  BEGIN
    IF NOT EXISTS(SELECT NULL FROM tdc_put_queue WHERE tx_lock IN ('H', 'R') AND tran_id = @tran_id)
        return -1
    UPDATE tdc_put_queue 
    SET tx_lock = CASE tx_lock
                    WHEN 'H' THEN 'M'
                    WHEN 'R' THEN 'N'
                  END
    WHERE tran_id = @tran_id
    return 0
  END
END
GO
GRANT EXECUTE ON  [dbo].[tdc_q_set_mgt_lock_sp] TO [public]
GO

SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_q_assign_trans_sp] (
@QueueTable varchar(30), 
@tran_id int, 
@sType Varchar(10), 
@sGrpUsrID varchar(25))
AS

IF @QueueTable = 'tdc_pick_queue'
BEGIN
  IF @sType = 'Group'
  BEGIN
    UPDATE tdc_pick_queue SET assign_group = @sGrpUsrID, assign_user_id = NULL
    WHERE tran_id = @tran_id AND tx_lock <> 'C' AND tx_lock <> '3'
  END
  ELSE IF @sType = 'User'
  BEGIN
    UPDATE tdc_pick_queue SET assign_user_id = @sGrpUsrID, assign_group = NULL
    WHERE tran_id = @tran_id AND tx_lock <> 'C' AND tx_lock <> '3'
  END
  ELSE IF @sType = '<UnAssign>'
  BEGIN
    UPDATE tdc_pick_queue SET assign_user_id = NULL, assign_group = NULL
    WHERE tran_id = @tran_id AND tx_lock <> 'C' AND tx_lock <> '3'
  END
END

IF @QueueTable = 'tdc_put_queue'
BEGIN
  IF @sType = 'Group'
  BEGIN
    UPDATE tdc_put_queue SET assign_group = @sGrpUsrID, assign_user_id = NULL
    WHERE tran_id = @tran_id AND tx_lock <> 'C'
  END
  ELSE IF @sType = 'User'
  BEGIN
    UPDATE tdc_put_queue SET assign_user_id = @sGrpUsrID, assign_group = NULL
    WHERE tran_id = @tran_id AND tx_lock <> 'C'
  END
  ELSE IF @sType = '<UnAssign>'
  BEGIN
    UPDATE tdc_put_queue SET assign_user_id = NULL, assign_group = NULL
    WHERE tran_id = @tran_id AND tx_lock <> 'C'
  END
END
GO
GRANT EXECUTE ON  [dbo].[tdc_q_assign_trans_sp] TO [public]
GO

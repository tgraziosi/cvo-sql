SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_pick_q_resequence_sp] (
    @iMoveFromSeqNo int, 
    @iMoveToSeqNo int, 
    @iPriority int)
AS
/**************************************************************************
tdc_pick_q_resequence_sp - This stored procedure is used to relocate a task
on the queue to a different sequence within a priority. Both sequences must 
exist on the same priority. The resequencing could be in any direction (i.e.
a task could be moved to a higher or lower sequence.
Parameters:
    @iMoveFromSeqNo - sequence of task to move
    @iMoveToSeqNo - target sequence
    @iPriority - task's priority

12/2/1999    Initial        Samuel Eniojukan
***************************************************************************/

DECLARE @SQLString Varchar(255)
DECLARE @iTmpPriority int
DECLARE @iCurSeqNo int
DECLARE @iTmpSeqNo int
DECLARE @iPrevSeqNo int
DECLARE @iTranID int
DECLARE @iFirstTranID int

-- determine move direction by comparing the From and To sequence numbers
IF @iMoveFromSeqNo > @iMoveToSeqNo
  -- moving up
  BEGIN
    DECLARE ResequenceSet CURSOR FAST_FORWARD FOR 
    SELECT priority, seq_no, tran_id 
    FROM tdc_pick_queue 
    WHERE Seq_no BETWEEN CONVERT(varchar(20), @iMoveToSeqNo) AND 
        CONVERT(varchar(20), @iMoveFromSeqNo) 
        AND priority = CONVERT(varchar(20), @iPriority) 
    ORDER BY seq_no DESC
    
    OPEN ResequenceSet

    -- to avoid having duplicate keys during re-sequencing, keep the last
    -- record away at priority 0 so we'll have room to push other records down
    FETCH NEXT FROM ResequenceSet INTO @iTmpPriority, @iCurSeqNo, @iTranID
    UPDATE tdc_pick_queue SET priority = 0 WHERE tran_id = @iTranID
    SELECT @iPrevSeqNo = @iCurSeqNo
    -- also hang on to its tran_id so it can be used to refference it later
    SELECT @iFirstTranID = @iTranID

    FETCH NEXT FROM ResequenceSet INTO @iTmpPriority, @iCurSeqNo, @iTranID
    WHILE (@@FETCH_STATUS <> -1)
    BEGIN
        IF (@@FETCH_STATUS <> -2)
        BEGIN
            -- set sequence number of current trans to that of the previous trans
            UPDATE tdc_pick_queue SET seq_no = @iPrevSeqNo WHERE tran_id = @iTranID
            -- keep sequnce number so it can be assigned to next trans
            SELECT @iPrevSeqNo = @iCurSeqNo
            FETCH NEXT FROM ResequenceSet INTO @iTmpPriority, @iCurSeqNo, @iTranID
        END
    END
    -- now remove the first trans from temporary priority 0, and give it the last sequence number
    UPDATE tdc_pick_queue SET seq_no = @iPrevSeqNo, priority = @iTmpPriority WHERE tran_id = @iFirstTranID
  END
ELSE
  -- moving down
  BEGIN
    DECLARE ResequenceSet CURSOR FAST_FORWARD FOR 
    SELECT priority, seq_no, tran_id 
    FROM tdc_pick_queue 
    WHERE Seq_no BETWEEN CONVERT(varchar(20), @iMoveFromSeqNo) AND 
        CONVERT(varchar(20), @iMoveToSeqNo) 
        AND priority = CONVERT(varchar(20), @iPriority) 
    ORDER BY seq_no
    
    OPEN ResequenceSet

    -- to avoid having duplicate keys during re-sequencing, keep the last
    -- record away at priority 0 so we'll have room to push other records down
    FETCH NEXT FROM ResequenceSet INTO @iTmpPriority, @iCurSeqNo, @iTranID
    UPDATE tdc_pick_queue SET priority = 0 WHERE tran_id = @iTranID
    SELECT @iPrevSeqNo = @iCurSeqNo
    -- also hang on to its tran_id so it can be used to refference it later
    SELECT @iFirstTranID = @iTranID
    FETCH NEXT FROM ResequenceSet INTO @iTmpPriority, @iCurSeqNo, @iTranID

    WHILE (@@FETCH_STATUS <> -1)
    BEGIN
        IF (@@FETCH_STATUS <> -2)
        BEGIN
            -- set sequence number of current trans to that of the previous trans
            UPDATE tdc_pick_queue SET seq_no = @iPrevSeqNo WHERE tran_id = @iTranID
            -- keep sequnce number so it can be assigned to next trans
            SELECT @iPrevSeqNo = @iCurSeqNo
            FETCH NEXT FROM ResequenceSet INTO @iTmpPriority, @iCurSeqNo, @iTranID
        END
    END
    -- now remove the first trans from temporary priority 0, and give it the last sequence number
    UPDATE tdc_pick_queue SET seq_no = @iPrevSeqNo, priority = @iTmpPriority WHERE tran_id = @iFirstTranID
  END
CLOSE ResequenceSet
DEALLOCATE ResequenceSet
return 0
GO
GRANT EXECUTE ON  [dbo].[tdc_pick_q_resequence_sp] TO [public]
GO

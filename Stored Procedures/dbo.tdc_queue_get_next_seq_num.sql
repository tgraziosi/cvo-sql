SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_queue_get_next_seq_num] 
	@queue_table varchar(30), 
	@priority int 
AS

DECLARE @seq_no int


SELECT @seq_no = next_sequence 
  FROM tdc_queue_seq_no_pool
 WHERE queue = @queue_table AND priority = @priority

IF @seq_no IS NULL OR @seq_no = 0 SELECT @seq_no = 1


IF @queue_table = 'tdc_pick_queue'
BEGIN
	IF EXISTS(SELECT * FROM tdc_pick_queue(NOLOCK) WHERE priority = @priority AND seq_no = @seq_no)
		WHILE EXISTS(SELECT * FROM tdc_pick_queue(NOLOCK) WHERE priority = @priority AND seq_no = @seq_no) SELECT @seq_no = @seq_no + 1
END
ELSE
BEGIN
	IF EXISTS(SELECT * FROM tdc_put_queue(NOLOCK) WHERE priority = @priority AND seq_no = @seq_no)
		WHILE EXISTS(SELECT * FROM tdc_put_queue(NOLOCK) WHERE priority = @priority AND seq_no = @seq_no) SELECT @seq_no = @seq_no + 1
END

IF EXISTS(SELECT * FROM tdc_queue_seq_no_pool WHERE queue = @queue_table AND priority = @priority)
	UPDATE tdc_queue_seq_no_pool SET next_sequence = @seq_no WHERE queue = @queue_table AND priority = @priority
ELSE
	INSERT INTO tdc_queue_seq_no_pool(queue, priority, next_sequence) values(@queue_table, @priority, @seq_no)

RETURN @seq_no

GO
GRANT EXECUTE ON  [dbo].[tdc_queue_get_next_seq_num] TO [public]
GO

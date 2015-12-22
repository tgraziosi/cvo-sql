SET QUOTED_IDENTIFIER ON
GO
SET ANSI_NULLS ON
GO

CREATE PROCEDURE [dbo].[tdc_bin_part_sequence] @location varchar(10), @part_no varchar(30), @fillqty decimal(20, 8) = null
AS
	IF NOT EXISTS (SELECT * FROM #selected_bins)
		RETURN

	DECLARE @maxseq int 
	DECLARE @rowid int, @seq_no int     
	DECLARE @minrowid int, @minseq_no int

	SELECT @maxseq = ISNULL(max(seq_no), 0)
          FROM tdc_bin_part_qty
         WHERE location = @location
            AND part_no = @part_no

	UPDATE #selected_bins
           SET seq_no = rowid + @maxseq
         WHERE seq_no = 0
           AND qty != 0
                  
	SELECT @minseq_no = isnull((SELECT min(seq_no) FROM #selected_bins), -1)                                
	SELECT @minrowid = isnull((SELECT min(rowid) FROM #selected_bins), -1)                                  
                                               
	SELECT @seq_no = seq_no FROM #selected_bins WHERE rowid = @minrowid                                     
	SELECT @rowid = rowid FROM #selected_bins WHERE seq_no = @minseq_no                                     
                                               
	WHILE @minseq_no >= 0               
	BEGIN                               
              IF((@rowid > @minrowid) AND (@seq_no > @minseq_no))                                                  
              BEGIN                            
                  UPDATE #selected_bins SET seq_no = @seq_no WHERE rowid = @rowid                                  
                  UPDATE #selected_bins SET seq_no = @minseq_no WHERE rowid = @minrowid                            
              END                              
                                               
              SELECT @minseq_no = isnull((SELECT min(seq_no) FROM #selected_bins WHERE seq_no > @minseq_no), -1)   
              SELECT @minrowid = isnull((SELECT min(rowid) FROM #selected_bins WHERE rowid > @minrowid), -1)       
                                               
              SELECT @seq_no = seq_no FROM #selected_bins WHERE rowid = @minrowid                                  
              SELECT @rowid = rowid FROM #selected_bins WHERE seq_no = @minseq_no                                  
	END                                 
          
	IF (@fillqty IS NOT NULL)
	BEGIN
		UPDATE #selected_bins                                          
		   SET qty = @fillqty
	
		UPDATE tdc_bin_part_qty                                        
		   SET qty = @fillqty, seq_no = a.seq_no                                       
		  FROM #selected_bins a, tdc_bin_part_qty b                    
		 WHERE b.location = @location
		   AND b.part_no  = @part_no
		   AND b.bin_no = a.bin_no    

		INSERT INTO tdc_bin_part_qty (location, part_no, bin_no, qty, seq_no)  
             	SELECT @location, @part_no, bin_no, @fillqty, seq_no
               	  FROM #selected_bins                                 
              	 WHERE bin_no NOT IN (	SELECT bin_no                   
                                     	  FROM tdc_bin_part_qty (nolock)   
                                    	 WHERE location = @location  
                                      	   AND part_no = @part_no )
       	END
	ELSE
	BEGIN
		UPDATE tdc_bin_part_qty
                   SET qty = a.qty, seq_no = a.seq_no
                  FROM #selected_bins a, tdc_bin_part_qty b
              	 WHERE b.location = @location
                   AND b.part_no = @part_no
                   AND b.bin_no = a.bin_no
                   AND a.qty > 0

		INSERT INTO tdc_bin_part_qty (location, part_no, bin_no, qty, seq_no)
		SELECT @location, @part_no, bin_no, qty, seq_no
		  FROM #selected_bins
		 WHERE qty > 0
		   AND bin_no NOT IN (SELECT bin_no
					FROM tdc_bin_part_qty (nolock)
				       WHERE location = @location
		                         AND part_no = @part_no )
	END

	IF OBJECT_ID('tempdb..#bin_part_qty') IS NOT NULL
	BEGIN
		TRUNCATE TABLE #bin_part_qty
	END
	ELSE
	BEGIN
		CREATE TABLE #bin_part_qty 
		(
			bin_no varchar(12) NOT NULL, 
			qty decimal(20,8) NULL, 
			rowid int identity NOT NULL
		)
	END
 
	INSERT INTO #bin_part_qty (bin_no, qty)
	    SELECT bin_no, qty
	      FROM tdc_bin_part_qty
	     WHERE location = @location
	       AND part_no = @part_no
	       AND [primary] = 'Y'

	INSERT INTO #bin_part_qty (bin_no, qty)
	    SELECT bin_no, qty
	      FROM tdc_bin_part_qty
	     WHERE location = @location
	       AND part_no = @part_no
	       AND [primary] = 'N'
	     ORDER BY seq_no
		
	IF NOT EXISTS (SELECT * FROM tdc_bin_part_qty WHERE location = @location AND part_no = @part_no AND [primary] = 'Y')
	BEGIN
		UPDATE tdc_bin_part_qty
		   SET seq_no = a.rowid + 1
		  FROM #bin_part_qty a, tdc_bin_part_qty b
		 WHERE b.location = @location
		   AND b.part_no  = @part_no
		   AND b.bin_no = a.bin_no
	END
	ELSE
	BEGIN
		UPDATE tdc_bin_part_qty
		   SET seq_no = a.rowid
		  FROM #bin_part_qty a, tdc_bin_part_qty b
		 WHERE b.location = @location
		   AND b.part_no  = @part_no
		   AND b.bin_no = a.bin_no
	END
GO
GRANT EXECUTE ON  [dbo].[tdc_bin_part_sequence] TO [public]
GO

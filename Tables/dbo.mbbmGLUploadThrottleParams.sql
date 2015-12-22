CREATE TABLE [dbo].[mbbmGLUploadThrottleParams]
(
[Attempts] [int] NOT NULL,
[ThrottleLevel] [int] NOT NULL,
[WaitTime] [int] NOT NULL
) ON [PRIMARY]
GO
GRANT REFERENCES ON  [dbo].[mbbmGLUploadThrottleParams] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmGLUploadThrottleParams] TO [Analytics]
GO
GRANT INSERT ON  [dbo].[mbbmGLUploadThrottleParams] TO [Analytics]
GO
GRANT DELETE ON  [dbo].[mbbmGLUploadThrottleParams] TO [Analytics]
GO
GRANT UPDATE ON  [dbo].[mbbmGLUploadThrottleParams] TO [Analytics]
GO
GRANT SELECT ON  [dbo].[mbbmGLUploadThrottleParams] TO [public]
GO
GRANT INSERT ON  [dbo].[mbbmGLUploadThrottleParams] TO [public]
GO
GRANT DELETE ON  [dbo].[mbbmGLUploadThrottleParams] TO [public]
GO
GRANT UPDATE ON  [dbo].[mbbmGLUploadThrottleParams] TO [public]
GO

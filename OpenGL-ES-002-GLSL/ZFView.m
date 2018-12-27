//
//  ZFView.m
//  OpenGL-ES-002-GLSL
//
//  Created by zhongding on 2018/12/25.
//

#import "ZFView.h"

#import <OpenGLES/ES3/gl.h>
#import <YYKit.h>
@interface ZFView()
@property(strong ,nonatomic) CAEAGLLayer *eaglLayer;
@property(strong ,nonatomic) EAGLContext *context;
@property(assign ,nonatomic) GLuint renderBuffer;
@property(assign ,nonatomic) GLuint frameBuffer;

@property(assign ,nonatomic) GLint program;
@end

@implementation ZFView


/*
 1、创建图层
 2、创新上下文
 3、清除buffer缓存
 4、创建renderBuffer
 5、创建frameBuffer
 6、绘制
 */

- (void)layoutSubviews{
    [self setupLayer];
    [self setupContext];
    [self deleteBufferData];
    [self setupRenderBuffer];
    [self setupFrameBuffer];
    [self setupShader];
    
}

#pragma mark *****************6、绘制
- (void)setupShader{
    
    glClear(GL_COLOR_BUFFER_BIT);
    glClearColor(0.0f, 1.0f, 0.0f, 1.0f);

    //窗口大小
    CGFloat scale = [[UIScreen mainScreen] scale];
    glViewport(self.frame.origin.x * scale, self.frame.origin.y * scale, self.frame.size.width * scale, self.frame.size.height * scale);

    
    self.program = [self loadProgram];
    //链接
    glLinkProgram(self.program);
    
    //获取链接状态
    GLint linkStatus;
    glGetProgramiv(self.program, GL_LINK_STATUS, &linkStatus);
    
    //链接出错
    if (linkStatus == GL_FASTEST) {
        //获取链接出错信息
        GLchar message[1024];
        glGetProgramInfoLog(self.program, sizeof(message), NULL, &message[0]);
        NSString *messageString = [NSString stringWithCString:message encoding:NSUTF8StringEncoding];
        NSLog(@"链接出错---%@",messageString);
        return;
    }
    NSLog(@"Program Link Success!");

    //使用program
    glUseProgram(self.program);
    
    //顶点纹理坐标
    GLfloat vertexts[] = {
        0.5f, -0.5f, 0,     1.0f, 0.0f,
        -0.5f, 0.5f, 0,     0.0f, 1.0f,
        -0.5f, -0.5f, 0,    0.0f, 0.0f,
        0.5f, 0.5f, 0,      1.0f, 1.0f,
        -0.5f, 0.5f, 0,     0.0f, 1.0f,
        0.5f, -0.5f, 0,     1.0f, 0.0f,
    
    };
    
    //定义一个顶点缓冲区
    GLuint attriBuffer;
    //申请缓冲区标识
    glGenBuffers(1, &attriBuffer);
    //绑定GL_ARRAY_BUFFER 标识
    glBindBuffer(GL_ARRAY_BUFFER, attriBuffer);
    //将数据从CPUd复制到gpu
    glBufferData(GL_ARRAY_BUFFER, sizeof(vertexts), vertexts, GL_DYNAMIC_DRAW);
    
    //将顶点数据通过myPrograme中的传递到顶点着色程序的position
    //1.glGetAttribLocation,用来获取vertex attribute的入口的.2.告诉OpenGL ES,通过glEnableVertexAttribArray，3.最后数据是通过glVertexAttribPointer传递过去的。
    //注意：第二参数字符串必须和shaderv.vsh中的输入变量：position保持一致
    
    GLuint position =glGetAttribLocation(self.program, "position");
    
    //使得GPU可以读取 position 里面的数据
    glEnableVertexAttribArray(position);
    
    //设置读取方式
    //参数1：index,顶点数据的索引
    //参数2：size,每个顶点属性的组件数量，1，2，3，或者4.默认初始值是4.
    //参数3：type,数据中的每个组件的类型，常用的有GL_FLOAT,GL_BYTE,GL_SHORT。默认初始值为GL_FLOAT
    //参数4：normalized,固定点数据值是否应该归一化，或者直接转换为固定值。（GL_FALSE）
    //参数5：stride,连续顶点属性之间的偏移量，默认为0；
    //参数6：指定一个指针，指向数组中的第一个顶点属性的第一个组件。默认为0
    glVertexAttribPointer(position, 3, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, NULL);
    
    //设置纹理坐标
    GLuint textCoordinate = glGetAttribLocation(self.program, "textCoordinate");
    glEnableVertexAttribArray(textCoordinate);
    glVertexAttribPointer(textCoordinate, 2, GL_FLOAT, GL_FALSE, sizeof(GLfloat)*5, (GLfloat*)NULL+3);
    
    //载入纹理
    [self setupTexture:@"timg-3"];
    
    //注意，想要获取shader里面的变量，这里记得要在glLinkProgram后面，后面，后面！
    /*
     一个一致变量在一个图元的绘制过程中是不会改变的，所以其值不能在glBegin/glEnd中设置。一致变量适合描述在一个图元中、一帧中甚至一个场景中都不变的值。一致变量在顶点shader和片断shader中都是只读的。首先你需要获得变量在内存中的位置，这个信息只有在连接程序之后才可获得
     */
    //rotate等于shaderv.vsh中的uniform属性，rotateMatrix
    GLuint rotate = glGetUniformLocation(self.program, "rotateMatrix");
    
    //获取渲染的弧度
    float radians = 180 * 3.14159f / 180.0f;
    //求得弧度对于的sin\cos值
    float s = sin(radians);
    float c = cos(radians);
    
    //z轴旋转矩阵 参考3D数学第二节课的围绕z轴渲染矩阵公式
    //为什么和公司不一样？因为在3D课程中用的是横向量，在OpenGL ES用的是列向量
    GLfloat zRotation[16] = {
        c, -s, 0, 0,
        s, c, 0, 0,
        0, 0, 1.0, 0,
        0.0, 0, 0, 1.0
    };
    
    //设置旋转矩阵
    glUniformMatrix4fv(rotate, 1, GL_FALSE, (GLfloat *)&zRotation[0]);
    
    
    glDrawArrays(GL_TRIANGLES, 0, 6);
    [self.context presentRenderbuffer:GL_RENDERBUFFER];
}



- (GLuint)loadProgram{
    //顶点着色器路径
    NSString *verTexFile = [[NSBundle mainBundle] pathForResource:@"shaderv" ofType:@"vsh"];
    
    NSString *fragmentFile = [[NSBundle mainBundle] pathForResource:@"shaderf" ofType:@"fsh"];
    
     //定义2个临时着色器对象
    GLuint vertexShader, fragmentShader;
    
    //编译顶点着色程序、片元着色器程序
    [self compileShader:&vertexShader type:GL_VERTEX_SHADER file:verTexFile];
    [self compileShader:&fragmentShader type:GL_FRAGMENT_SHADER file:fragmentFile];
    
     //创建program
    GLint program = glCreateProgram();
    
    //创建最终的程序
    glAttachShader(program, vertexShader);
    glAttachShader(program, fragmentShader);
    
    
      //释放不需要的shader
    glDeleteShader(vertexShader);
    glDeleteShader(fragmentShader);
 
    return program;
}

//链接shader
- (void)compileShader:(GLuint *)shader type:(GLenum)type file:(NSString *)file{
    //获取着色器里面的字符串内容
    NSString *content = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:nil];
    
    //转化为C字符串
    const GLchar * source = (GLchar*)[content UTF8String];
    
    //根据类型创建shader
    *shader = glCreateShader(type);
    
    //将着色器源码附加到着色器对象上。
    //参数1：shader,要编译的着色器对象 *shader
    //参数2：numOfStrings,传递的源码字符串数量 1个
    //参数3：strings,着色器程序的源码（真正的着色器程序源码）
    //参数4：lenOfStrings,长度，具有每个字符串长度的数组，或NULL，这意味着字符串是NULL终止的
    glShaderSource(*shader, 1, &source, NULL);
    
    //把着色器源代码编译成目标代码
    glCompileShader(*shader);
}

//加载纹理
-(void)setupTexture:(NSString*)filename{
    //获取图片对象
    CGImageRef imageRef = [UIImage imageNamed:filename].CGImage;
    //读取出错
    if (!imageRef) {
        NSLog(@"读取纹理出错");
        return;
    }
    NSLog(@"读取纹理成功");
    
    //获取图片宽高
    size_t widht = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
    
    //开辟图片数据存储空间,获取图片字节数 宽*高*4（RGBA）
    GLubyte *imagedData = (GLubyte*) calloc(widht*height*4,sizeof(GLubyte));
    
    //创建上下文
    /*
     参数1：data,指向要渲染的绘制图像的内存地址
     参数2：width,bitmap的宽度，单位为像素
     参数3：height,bitmap的高度，单位为像素
     参数4：bitPerComponent,内存中像素的每个组件的位数，比如32位RGBA，就设置为8
     参数5：bytesPerRow,bitmap的没一行的内存所占的比特数
     参数6：colorSpace,bitmap上使用的颜色空间  kCGImageAlphaPremultipliedLast：RGBA
     */
    CGContextRef contextRef = CGBitmapContextCreate(imagedData, widht, height, 8, widht*4, CGImageGetColorSpace(imageRef), kCGImageAlphaPremultipliedLast);
    
    CGRect rect = CGRectMake(0, 0, widht, height);
    
    //在CGContextRef上绘图
    /*
     CGContextDrawImage 使用的是Core Graphics框架，坐标系与UIKit 不一样。UIKit框架的原点在屏幕的左上角，Core Graphics框架的原点在屏幕的左下角。
     CGContextDrawImage
     参数1：绘图上下文
     参数2：rect坐标
     参数3：绘制的图片
     */
    CGContextDrawImage(contextRef, rect, imageRef);
    //释放上下文
    CGContextRelease(contextRef);
    
    
    //绑定纹理到默认的纹理ID（这里只有一张图片，故而相当于默认于片元着色器里面的colorMap，如果有多张图不可以这么做）
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //sh
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
    glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
    
    //载入纹理2D数据
    /*
     参数1：纹理模式，GL_TEXTURE_1D、GL_TEXTURE_2D、GL_TEXTURE_3D
     参数2：加载的层次，一般设置为0
     参数3：纹理的颜色值GL_RGBA
     参数4：宽
     参数5：高
     参数6：border，边界宽度
     参数7：format
     参数8：type
     参数9：纹理数据
     */
    float w = widht,h = height;
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, w, h, 0, GL_RGBA, GL_UNSIGNED_BYTE, imagedData);
    
    glBindTexture(GL_TEXTURE_2D, 0);
    
    //释放imagedData
    free(imagedData);
}
#pragma mark *****************5、创建frameBuffer
- (void)setupFrameBuffer{
    //1.定义一个缓存区
    GLuint Buffer;
    
    //2.申请一个缓存区标志
    glGenFramebuffers(1, &Buffer);
    
    //3.将标识符绑定到GL_FRAMEBUFFER
    glBindFramebuffer(GL_FRAMEBUFFER, Buffer);
    self.frameBuffer = Buffer;
    
    //生成空间之后，则需要将renderbuffer跟framebuffer进行绑定，调用glFramebufferRenderbuffer函数进行绑定，后面的绘制才能起作用
    //5.将renderBuffer 通过glFramebufferRenderbuffer函数绑定到GL_COLOR_ATTACHMENT0上。
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,GL_RENDERBUFFER , self.renderBuffer);
}

#pragma mark *****************4、创建renderBuffer
- (void)setupRenderBuffer{
   //1.定义一个缓存区
    GLuint buffer;
    
    //2.申请一个缓存区标志
    glGenRenderbuffers(1, &buffer);
    self.renderBuffer = buffer;
    
    //3.将标识符绑定到GL_RENDERBUFFER
    glBindRenderbuffer(GL_RENDERBUFFER, buffer);
    
    //4.RenderBuffer渲染缓存区分配存储空间
    [self.context renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.eaglLayer];
    
}

#pragma mark *****************3、清除buffer缓存
- (void)deleteBufferData{
    //1.导入框架#import <OpenGLES/ES2/gl.h>
    /*
     2.创建2个帧缓存区，渲染缓存区，帧缓存区
     @property (nonatomic , assign) GLuint myColorRenderBuffer;
     @property (nonatomic , assign) GLuint myColorFrameBuffer;
     
     A.离屏渲染，详细解释见课件
     
     B.buffer的分类,详细见课件
     
     buffer分为frame buffer 和 render buffer2个大类。其中frame buffer 相当于render buffer的管理者。frame buffer object即称FBO，常用于离屏渲染缓存等。render buffer则又可分为3类。colorBuffer、depthBuffer、stencilBuffer。
     //绑定buffer标识符
     glGenRenderbuffers(GLsizei n, <#GLuint *renderbuffers#>)
     glGenFramebuffers(GLsizei n, <#GLuint *framebuffers#>)
     //绑定空间
     glBindRenderbuffer(<#GLenum target#>, <#GLuint renderbuffer#>)
     glBindFramebuffer(<#GLenum target#>, <#GLuint framebuffer#>)
     
     
     */
    
    glDeleteBuffers(1, &_renderBuffer);
    self.renderBuffer = 0;
    
    glDeleteBuffers(1, &_frameBuffer);
    self.frameBuffer = 0;

}

#pragma mark *****************2、创新上下文
- (void)setupContext{
    //通过制定版本创建上下文
    self.context = [[EAGLContext alloc] initWithAPI:(kEAGLRenderingAPIOpenGLES3)];
    
    //是否创建成功
    if (!self.context) {
        NSLog(@"contexto init failed");
        return;
    }
    
    //是否设置当前上下文成功
    if (![EAGLContext setCurrentContext:self.context]) {
        NSLog(@"setCurrentContext failed");
        return;
    }
}

#pragma mark *****************1、创建图层
- (void)setupLayer{
    
    //不能直接强制赋值，需重写layerClass方法
    self.eaglLayer = (CAEAGLLayer *)self.layer;
    
    [self setContentScaleFactor:[[UIScreen mainScreen]scale]];

    //layer 默认透明，需将其设置为不透明
    self.eaglLayer.opaque = YES;
    
    //设置描述属性，这里设置不维持渲染内容以及颜色格式为RGBA8
    /*
     kEAGLDrawablePropertyRetainedBacking                          表示绘图表面显示后，是否保留其内容。这个key的值，是一个通过NSNumber包装的bool值。如果是false，则显示内容后不能依赖于相同的内容，ture表示显示后内容不变。一般只有在需要内容保存不变的情况下，才建议设置使用,因为会导致性能降低、内存使用量增减。一般设置为flase.
     
     kEAGLDrawablePropertyColorFormat
     可绘制表面的内部颜色缓存区格式，这个key对应的值是一个NSString指定特定颜色缓存区对象。默认是kEAGLColorFormatRGBA8；
     kEAGLColorFormatRGBA8：32位RGBA的颜色，4*8=32位
     kEAGLColorFormatRGB565：16位RGB的颜色，
     kEAGLColorFormatSRGBA8：sRGB代表了标准的红、绿、蓝，即CRT显示器、LCD显示器、投影机、打印机以及其他设备中色彩再现所使用的三个基本色素。sRGB的色彩空间基于独立的色彩坐标，可以使色彩在不同的设备使用传输中对应于同一个色彩坐标体系，而不受这些设备各自具有的不同色彩坐标的影响。
     
     
     */
    self.eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:false],kEAGLDrawablePropertyRetainedBacking,kEAGLColorFormatRGBA8,kEAGLDrawablePropertyColorFormat,nil];
}


+ (Class)layerClass{
    return [CAEAGLLayer class];
}

@end

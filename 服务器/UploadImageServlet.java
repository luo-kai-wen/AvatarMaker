package com.fenhongxiang

import java.awt.image.BufferedImage;
import java.io.ByteArrayInputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.File;
import java.io.FileOutputStream;
import java.io.IOException;
import java.util.UUID;

import javax.imageio.ImageIO;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import sun.misc.BASE64Decoder;


/**
 * @author LuoJiangHong
 * 
 * 获取Flex端传来的图片数据（Base64字符串形式），把图片保存到服务器指定目录，并返回图片地址（相对于根目录的地址）
 *
 */
public class UploadImageServlet extends HttpServlet 
{

	private static final long serialVersionUID = 1L;


	public UploadImageServlet() 
	{
		super();
	}
	    
	public void destroy() 
	{
		super.destroy();
	}

	protected void doGet(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException 
	{ 
		try 
		{
			processRequest(request, response);
		} 
		catch (Exception e) 
		{
			e.printStackTrace();
		}
	}    
	  
	protected void doPost(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException 
	{    
		try 
		{
			processRequest(request, response);
		} 
		catch (Exception e) 
		{
			e.printStackTrace();
		} 
	}    
	
	protected void processRequest(HttpServletRequest request, HttpServletResponse response)  throws ServletException, IOException 
	{
		response.setContentType("text/html;charset=UTF-8");   
        response.setHeader("Pragma", "No-cache");   
        response.setHeader("Cache-Control", "no-cache");   
        response.setDateHeader("Expires", 0);   
  
        String bitmap_data = request.getParameter("bitmap_data");   
        
        BASE64Decoder decoder = new BASE64Decoder();

        //Base64解码
         byte[] b = decoder.decodeBuffer(bitmap_data);
            for(int i=0;i<b.length;++i)
            {
                if(b[i]<0)
                {//调整异常数据
                    b[i]+=256;
                }
            }
            
        BufferedImage img=ImageIO.read(new ByteArrayInputStream(b)); 

		try 
		{   
            ByteArrayOutputStream bao = new ByteArrayOutputStream();   
            ImageIO.write(img, "jpg", bao);   
            byte[] data = bao.toByteArray();  
            
            @SuppressWarnings("deprecation")
			String filePath = request.getRealPath("/videoShot");
            //判断路径是否存在,若不存在则创建路径
            File upDir = new File(filePath);
            if (!upDir.exists())
            {
                upDir.mkdir();
            }
            //生成随机文件名
            String saveName = UUID.randomUUID().toString(); ;
            String fileName = saveName + ".jpg";
            
    		System.out.println(fileName);

            //写图片
            File f = new File(filePath+"\\" + fileName);
    		DataOutputStream dos = new DataOutputStream(new FileOutputStream(f));
    		dos.write(data);
    		dos.flush();
    		dos.close();
    		response.setContentType("text/xml");   
            response.getWriter().write("/videoShot/" + fileName);   
        }
        catch(Exception ex)
        {
        	response.setContentType("text/xml");   
            response.getWriter().write("保存失败");   
    		System.out.println("保存失败");
        }
	}

}

// package com.mapper;

// import com.entity.User;
// import com.service.IUserService;
// import com.service.exception.ServiceException;
// import org.junit.Test;
// import org.junit.runner.RunWith;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.boot.test.context.SpringBootTest;
// import org.springframework.test.context.junit4.SpringRunner;

// @RunWith(SpringRunner.class)
// @SpringBootTest
// public class UserServiceTest {
//     @Autowired
//     private IUserService iUserService;
//     @Test
//     public void log(){
//         try {
//             iUserService.log(1,"81818181");
//             System.out.println("登录成功！");
//         } catch (ServiceException e) {
//             System.out.println("注册失败！" + e.getClass().getSimpleName());
//             System.out.println(e.getMessage());
//         }
//     }
//     @Test
//     public void reg(){
//         try{
//             iUserService.reg("222222","tes",1,"110110");
//             System.out.println("注册成功！");
//         }
//         catch (ServiceException e) {
//             System.out.println("注册失败！" + e.getClass().getSimpleName());
//             System.out.println(e.getMessage());
//         }
//     }
//     @Test
//     public void log2(){
//         try{
//             iUserService.log(14,"222222");
//             System.out.println("登陆成功");
//         }catch (ServiceException e) {
//             System.out.println("登录失败！" + e.getClass().getSimpleName());
//             System.out.println(e.getMessage());
//         }
//     }
//     @Test
//     public void update(){
//         try{
//             iUserService.up(14,"222222","111111","adminer",0,"202020");
//             System.out.println("修改成果");
//         }catch (ServiceException e) {
//             System.out.println("修改失败！" + e.getClass().getSimpleName());
//             System.out.println(e.getMessage());
//         }
//     }

// }

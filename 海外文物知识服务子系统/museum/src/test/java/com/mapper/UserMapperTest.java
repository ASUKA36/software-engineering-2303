// package com.mapper;
// import com.entity.User;
// import com.service.IUserService;
// import org.junit.Test;
// import org.springframework.boot.test.context.SpringBootTest;
// import org.junit.runner.RunWith;
// import org.springframework.beans.factory.annotation.Autowired;
// import org.springframework.test.context.junit4.SpringRunner;

// @SpringBootTest//标注当前类是测试类
// @RunWith(SpringRunner.class)
// public class UserMapperTest {
//     @Autowired
//     private UserMapper userMapper;

//     @Autowired
//     private IUserService iUserService;
//     @Test
//     public void findByUser_id()
//     {
//         User result = userMapper.findByUser_id(1);
//         System.out.println(result.toString());
//     }

//     @Test
//     public void insert_user(){
//         User result = new User();
//         result.setUser_password("778899");
//         result.setUser_name("琳琳");
//         result.setUser_sex(0);
//         result.setUser_tel("102938");
//         int row = userMapper.insert_user(result);
//         System.out.println(row);
//     }

//     @Test
//     public void update_user(){
//         User user = new User();
// //        user = userMapper.findByUser_password(1,"18181818");
// //        if(user==null) {
// //            System.out.println("密码错误");
// //        }
// //        else{
// //            user.setUser_id(1);
// //            user.setUser_password("81818181");
// //            user.setUser_name("小斯斯");
// //            user.setUser_sex(0);
// //            user.setUser_tel("666666");
//             int row = iUserService.up(1,"81818181","18181818","sisi",0,"999999");
//             System.out.println(row);
//         }

// ///

//     @Test
//     public void delete_user(){
//         User user = userMapper.findByUser_id(4);
//         int row = userMapper.delete(user);
//         System.out.println(row);
//     }
//     @Test
//     public void findByUser_name(){
// //        int i=0;
// //        i = userMapper.findByUser_name("666");
// //        System.out.println(i);
//     }
// }

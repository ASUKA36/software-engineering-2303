<template>
  <el-container>
    <!--aside部分-->
    <el-aside width="415px">
      <el-col :span="12">
        <h5>默认颜色</h5>
        <el-menu
          default-active="1"
          class="el-menu-vertical-demo"
          @open="handleOpen"
          @close="handleClose">

          <el-menu-item index="1">
            <i class="el-icon-document"></i>
            <span slot="title">个人资料</span>
          </el-menu-item>
          <el-menu-item index="2">
            <i class="el-icon-star-on"></i>
            <span slot="title">我的收藏</span>
          </el-menu-item>
          <el-submenu index="3">
            <template slot="title">
              <i class="el-icon-chat-square"></i>
              <span>我的评论</span>
            </template>
            <el-menu-item-group>
              <!--                                    <template slot="title">评论</template>-->
              <el-menu-item index="1-1">评论</el-menu-item>
              <el-menu-item index="1-2">回复</el-menu-item>
            </el-menu-item-group>
            <!--                                <el-menu-item-group title="分组2">-->
            <!--                                    <el-menu-item index="1-3">选项3</el-menu-item>-->
            <!--                                </el-menu-item-group>-->
            <!--                                <el-submenu index="1-4">-->
            <!--                                    <template slot="title">选项4</template>-->
            <!--                                    <el-menu-item index="1-4-1">选项1</el-menu-item>-->
            <!--                                </el-submenu>-->
          </el-submenu>

          <el-menu-item index="4" disabled>
            <i class="el-icon-setting"></i>
            <span slot="title">导航四</span>
          </el-menu-item>
        </el-menu>
      </el-col>
    </el-aside>

    <!--main部分-->
<!--    <el-main>
      <template>
        <el-table :data="tableData" border stripe highlight-current-row fit>
          <el-table-column
            prop="date"
            label="日期"
            width="180">
          </el-table-column>
          <el-table-column
            prop="name"
            label="姓名"
            width="180">
          </el-table-column>
          <el-table-column
            prop="address"
            label="地址">
          </el-table-column>
          <el-table-column label="操作">
            <el-button type="primary" >编辑</el-button>
            <el-button type="danger" >删除</el-button>
          </el-table-column>
        </el-table>
      </template>
    </el-main>-->
  </el-container>
</template>

<script>
export default {
  name: 'personal-page'
}
</script>

<style scoped>

</style>

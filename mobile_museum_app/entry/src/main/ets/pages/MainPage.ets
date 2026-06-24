import { HomePage } from './HomePage';
import { SearchPage } from './SearchPage';
import { ProfilePage } from './ProfilePage';
import { AppColors } from '../common/Constants';
import { UserSession } from '../store/UserSession';

@Component
export struct MainPage {
  @State currentTab: number = 0;

  tabIcon(index: number): string {
    if (index === 0) {
      return '🏺';
    }
    if (index === 1) {
      return '🔍';
    }
    return '👤';
  }

  build() {
    Tabs({ barPosition: BarPosition.End, index: this.currentTab }) {
      TabContent() {
        HomePage()
      }
      .tabBar(this.tabBuilder('瓷器', 0))

      TabContent() {
        SearchPage()
      }
      .tabBar(this.tabBuilder('搜索', 1))

      TabContent() {
        ProfilePage()
      }
      .tabBar(this.tabBuilder('我的', 2))
    }
    .barMode(BarMode.Fixed)
    .barBackgroundColor(AppColors.CARD)
    .barOverlap(false)
    .divider({ strokeWidth: 1, color: AppColors.BORDER, startMargin: 0, endMargin: 0 })
    .onChange((idx: number) => {
      this.currentTab = idx;
      if (idx === 2) {
        UserSession.bumpProfileRefresh();
      }
    })
    .width('100%')
    .height('100%')
    .backgroundColor(AppColors.BG)
  }

  @Builder
  tabBuilder(title: string, index: number) {
    Column({ space: 3 }) {
      Text(this.tabIcon(index))
        .fontSize(this.currentTab === index ? 20 : 18)
        .opacity(this.currentTab === index ? 1 : 0.65)
      Text(title)
        .fontSize(11)
        .fontColor(this.currentTab === index ? AppColors.PRIMARY : AppColors.SUBTEXT)
        .fontWeight(this.currentTab === index ? FontWeight.Bold : FontWeight.Normal)
      if (this.currentTab === index) {
        Row()
          .width(20)
          .height(3)
          .backgroundColor(AppColors.ACCENT)
          .borderRadius(2)
      } else {
        Row().height(3)
      }
    }
    .height(56)
    .justifyContent(FlexAlign.Center)
  }
}

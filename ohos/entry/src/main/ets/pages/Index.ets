import common from '@ohos.app.ability.common';
import { FlutterPage } from '@ohos/flutter_ohos';

const EVENT_BACK_PRESS = 'EVENT_BACK_PRESS';

@Entry
@Component
struct Index {
  private context: common.UIAbilityContext = getContext(this) as common.UIAbilityContext;

  build() {
    // FlutterPage 会自动从 FlutterAbility 获取 viewId "oh_flutter_1"
    // @Entry 装饰的组件必须有一个容器组件作为根节点
    Column() {
      FlutterPage({ viewId: "oh_flutter_1" })
        .width('100%')
        .height('100%')
    }
    .width('100%')
    .height('100%')
  }

  onBackPress(): boolean {
    this.context.eventHub.emit(EVENT_BACK_PRESS);
    return true;
  }
}
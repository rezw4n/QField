import QtQuick 2.3
import QtTest 1.0
import org.smartfield 1.0
import Theme 1.0
import "../../src/qml/" as SmartFieldControls
import "Utils.js" as Utils

TestCase {
  name: "SmartFieldGuide"
  when: windowShown

  Item {
    id: dummyParent
    width: 800
    height: 800

    Item {
      id: dummyItem1
      width: 50
      height: 50
    }

    Item {
      id: dummyItem2
      width: 50
      height: 50
      anchors.right: parent.right
    }

    Item {
      id: dummyItem3
      width: 50
      height: 50
      anchors.right: parent.right
      anchors.bottom: parent.bottom
    }

    Item {
      id: dummyItem4
      width: 50
      height: 50
      anchors.bottom: parent.bottom
    }

    SmartFieldControls.SmartFieldGuide {
      id: testTour
      baseRoot: dummyParent
      steps: [{
          "title": qsTr("dummyItem1"),
          "description": qsTr("dummyItem1 responsibility."),
          "target": () => [dummyItem1]
        }, {
          "title": qsTr("dummyItem2"),
          "description": qsTr("dummyItem2 responsibility."),
          "target": () => [dummyItem2]
        }, {
          "title": qsTr("dummyItem3"),
          "description": qsTr("dummyItem3 responsibility."),
          "target": () => [dummyItem3]
        }, {
          "title": qsTr("dummyItem4"),
          "description": qsTr("dummyItem4 responsibility."),
          "target": () => [dummyItem4]
        }]
    }
  }

  /**
   * Tests the SmartFieldGuide tour content item.
   *
   * Scenario: Navigating through the SmartFieldGuide
   *
   * This test checks that the internal title, description, and button text are updated correctly
   * as the user navigates through the tour.
   */
  function test_00_SmartFieldGuide() {
    const internalTitle = Utils.findChildren(testTour.contentItem, "guideInternalTitle");
    const internalDescription = Utils.findChildren(testTour.contentItem, "guideInternalDescription");
    const nextButton = Utils.findChildren(testTour.contentItem, "nextButton");
    const previousButton = Utils.findChildren(testTour.contentItem, "previousButton");
    testTour.open();
    compare(internalTitle.text, "dummyItem1");
    compare(internalDescription.text, "dummyItem1 responsibility.");
    compare(nextButton.text, "Next");
    compare(nextButton.isLast, false);
    nextButton.clicked();
    compare(internalTitle.text, "dummyItem2");
    compare(internalDescription.text, "dummyItem2 responsibility.");
    compare(nextButton.text, "Next");
    compare(nextButton.isLast, false);
    nextButton.clicked();
    compare(internalTitle.text, "dummyItem3");
    compare(internalDescription.text, "dummyItem3 responsibility.");
    compare(nextButton.text, "Next");
    compare(nextButton.isLast, false);
    nextButton.clicked();
    compare(internalTitle.text, "dummyItem4");
    compare(internalDescription.text, "dummyItem4 responsibility.");
    compare(nextButton.text, "Finish");
    compare(nextButton.isLast, true);
    previousButton.clicked();
    compare(internalTitle.text, "dummyItem3");
    compare(internalDescription.text, "dummyItem3 responsibility.");
    compare(nextButton.text, "Next");
    compare(nextButton.isLast, false);
  }
}

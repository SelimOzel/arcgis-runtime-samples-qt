// Copyright 2015 Esri.

// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
// http://www.apache.org/licenses/LICENSE-2.0

// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#ifndef SET_INITIAL_MAP_LOCATION_H
#define SET_INITIAL_MAP_LOCATION_H

namespace Esri {
namespace ArcGISRuntime {
  class Map;
  class MapGraphicsView;
  }
}

#include <QWidget>

class SetInitialMapLocation : public QWidget
{
  Q_OBJECT

public:
  explicit SetInitialMapLocation(QWidget* parent = 0);
  ~SetInitialMapLocation();

private:
  Esri::ArcGISRuntime::Map* m_map;
  Esri::ArcGISRuntime::MapGraphicsView* m_mapView;
};

#endif // SET_INITIAL_MAP_LOCATION_H

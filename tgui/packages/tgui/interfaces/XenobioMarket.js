/* eslint-disable max-len */

import { useBackend, useLocalState } from '../backend';
import { Box, Button, Section, Stack, Table, Tabs } from '../components';
import { Window } from '../layouts';
import { classes } from 'common/react';

const logScale = value => Math.log2(16 + Math.max(0, value)) - 4;


const SlimeMarket = (props, context) => {
  const { act, data } = useBackend(context);
  return (
    <Table>
      {data.prices.map(price_row => (
        <Table.Row key={price_row.key}>
          {price_row.prices.map(slime_price => (
            <Table.Cell width="25%" key={slime_price.key}>
              {!!slime_price.price && (
                <Section style={{ "border-radius": "5px" }} mb="6px">
                  <Stack fill>
                    <Stack.Item>
                      <Box className={classes([
                        'xenobio_market32x32',
                        slime_price.icon,
                      ])} />
                    </Stack.Item>
                    <Stack.Item mt="10px">
                      Currect price: {slime_price.price} points.
                    </Stack.Item>
                  </Stack>
                </Section>
              )}
            </Table.Cell>
          ))}
        </Table.Row>
      ))}
    </Table>
  );
};

const IntergalacticBounties = (props, context) => {
  const { act, data } = useBackend(context);
  const [galaxyTabIndex, setGalaxyTabIndex] = useLocalState(context, 'galaxyTabIndex', 1);
  return (
    <Stack grow>
      <Stack.Item>
        <Stack vertical>
          <Stack.Item>
            <Tabs vertical fill style={{ "border-radius": "5px" }}>
              <Tabs.Tab
                key={1}
                selected={galaxyTabIndex === 1}
                icon="flask"
                onClick={() => setGalaxyTabIndex(1)}>
                Slime Market
              </Tabs.Tab>
              <Tabs.Tab
                key={2}
                selected={galaxyTabIndex === 2}
                icon="globe"
                onClick={() => setGalaxyTabIndex(2)}>
                Intergalactic Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={3}
                selected={galaxyTabIndex === 3}
                icon="rocket"
                onClick={() => setGalaxyTabIndex(3)}>
                Station Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={1}
                selected={galaxyTabIndex === 1}
                icon="flask"
                onClick={() => setGalaxyTabIndex(1)}>
                Slime Market
              </Tabs.Tab>
              <Tabs.Tab
                key={2}
                selected={galaxyTabIndex === 2}
                icon="globe"
                onClick={() => setGalaxyTabIndex(2)}>
                Intergalactic Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={3}
                selected={galaxyTabIndex === 3}
                icon="rocket"
                onClick={() => setGalaxyTabIndex(3)}>
                Station Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={1}
                selected={galaxyTabIndex === 1}
                icon="flask"
                onClick={() => setGalaxyTabIndex(1)}>
                Slime Market
              </Tabs.Tab>
              <Tabs.Tab
                key={2}
                selected={galaxyTabIndex === 2}
                icon="globe"
                onClick={() => setGalaxyTabIndex(2)}>
                Intergalactic Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={3}
                selected={galaxyTabIndex === 3}
                icon="rocket"
                onClick={() => setGalaxyTabIndex(3)}>
                Station Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={1}
                selected={galaxyTabIndex === 1}
                icon="flask"
                onClick={() => setGalaxyTabIndex(1)}>
                Slime Market
              </Tabs.Tab>
              <Tabs.Tab
                key={2}
                selected={galaxyTabIndex === 2}
                icon="globe"
                onClick={() => setGalaxyTabIndex(2)}>
                Intergalactic Bounties
              </Tabs.Tab>
              <Tabs.Tab
                key={3}
                selected={galaxyTabIndex === 3}
                icon="rocket"
                onClick={() => setGalaxyTabIndex(3)}>
                Station Bounties
              </Tabs.Tab>
            </Tabs>
          </Stack.Item>
          <Stack.Item>
            <Section title="Current Contract" style={{ "border-radius": "5px" }} width="180px">
              <Box>
                3 red cores, 5 blue cores, 2 cubomelons, 6 green cocks, 8 socks.
              </Box>
              <Box>
                Requested by: Wabbajack Industries
              </Box>
            </Section>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow>
        <Stack vertical grow>
          <Stack.Item>
            <Section title="Wabbajack Industries" grow>
              A huge ass company, thats it.
            </Section>
          </Stack.Item>
          <Stack.Item grow>
            <Table>
              <Table.Row>
                <Table.Cell>
                  <Section title="Contract 1" mb="6px">
                    <Box>
                      Specialisation: Heavy Weaponery.
                    </Box>
                    <Button mt="7px" ml="40%" width="20%" textAlign="center">
                      Reee
                    </Button>
                  </Section>
                </Table.Cell>
                <Table.Cell>
                  <Section title="Contract 2" mb="6px">
                    <Box>
                      Specialisation: Heavy Weaponery.
                    </Box>
                    <Button mt="7px" ml="40%" width="20%" textAlign="center">
                      Reee
                    </Button>
                  </Section>
                </Table.Cell>
              </Table.Row>
              <Table.Row>
                <Table.Cell>
                  <Section title="Contract 3" mb="6px">
                    <Box>
                      Specialisation: Heavy Weaponery.
                    </Box>
                    <Button mt="7px" ml="40%" width="20%" textAlign="center">
                      Reee
                    </Button>
                  </Section>
                </Table.Cell>
                <Table.Cell>
                  <Section title="Contract 4" mb="6px">
                    <Box>
                      Specialisation: Heavy Weaponery.
                    </Box>
                    <Button mt="7px" ml="40%" width="20%" textAlign="center">
                      Reee
                    </Button>
                  </Section>
                </Table.Cell>
              </Table.Row>
            </Table>
          </Stack.Item>
        </Stack>
      </Stack.Item>
    </Stack>
  );
};

export const XenobioMarket = (props, context) => {
  const { act, data } = useBackend(context);
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 1);
  return (
    <Window
      width={tabIndex === 1 && 900 || 680}
      height={tabIndex === 1 && 412 || 500}>
      <Window.Content>
        <Tabs style={{ "border-radius": "5px" }}>
          <Tabs.Tab
            key={1}
            selected={tabIndex === 1}
            icon="flask"
            onClick={() => setTabIndex(1)}>
            Slime Market
          </Tabs.Tab>
          <Tabs.Tab
            key={2}
            selected={tabIndex === 2}
            icon="globe"
            onClick={() => setTabIndex(2)}>
            Intergalactic Bounties
          </Tabs.Tab>
          <Tabs.Tab
            key={3}
            selected={tabIndex === 3}
            icon="rocket"
            onClick={() => setTabIndex(3)}>
            Station Bounties
          </Tabs.Tab>
        </Tabs>
        <Box>
          {tabIndex === 1 && (
            <SlimeMarket />
          )}
          {tabIndex === 2 && (
            <IntergalacticBounties />
          )}
        </Box>
      </Window.Content>
    </Window>
  );
};

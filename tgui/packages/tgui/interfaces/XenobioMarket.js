import { useBackend, useLocalState } from '../backend';
import { Box, Button, LabeledList, NoticeBox, Section, Stack, Table, Tabs } from '../components';
import { Window } from '../layouts';
import { classes } from 'common/react';

export const XenobioMarket = (_, context) => {
  const [tabIndex, setTabIndex] = useLocalState(context, 'tabIndex', 1);

  return (
    <Window
      width={(tabIndex === 1 && 900) || 680}
      height={(tabIndex === 1 && 412) || 500}>
      <Window.Content>
        <Tabs style={{ 'border-radius': '5px' }}>
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
          {tabIndex === 1 && <SlimeMarket />}
          {tabIndex === 2 && <IntergalacticBounties />}
        </Box>
      </Window.Content>
    </Window>
  );
};

const SlimeMarket = (_, context) => {
  const { data } = useBackend(context);
  const { prices } = data;

  return (
    <Table>
      {prices.map((price_row) => (
        <Table.Row key={price_row.key}>
          {price_row.prices.map((slime_price) => (
            <Table.Cell width="25%" key={slime_price.key}>
              {!!slime_price.price && (
                <Section style={{ 'border-radius': '5px' }} mb="6px">
                  <Stack fill>
                    <Stack.Item>
                      <Box
                        className={classes([
                          'xenobio_market32x32',
                          slime_price.icon,
                        ])}
                      />
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

const IntergalacticBounties = (_, context) => {
  const { act, data } = useBackend(context);
  const { companies } = data;
  const [selectedCompany, setSelectedCompany] = useLocalState(
    context,
    'selectedCompany',
    companies[0].name,
  );

  return (
    <Stack>
      <Stack.Item width="220px">
        <Stack vertical>
          <Stack.Item>
            <Tabs vertical style={{ 'border-radius': '5px' }}>
              {companies.map((company) => (
                <Tabs.Tab
                  key={company.name}
                  selected={selectedCompany === company.name}
                  icon={company.icon}
                  onClick={() => setSelectedCompany(company.name)}>
                  {company.name}
                </Tabs.Tab>
              ))}
            </Tabs>
          </Stack.Item>
          <Stack.Item>
            <CurrentBounty />
          </Stack.Item>
          <Stack.Item>
            <Button width="100%"
              textAlign="center"
              onClick={() => act('send_bounty')}
            >
              Send Bounty
            </Button>
          </Stack.Item>
        </Stack>
      </Stack.Item>
      <Stack.Item grow>
        <BountyInfo selectedCompany={selectedCompany} />
      </Stack.Item>
    </Stack>
  );
};

const CurrentBounty = (_, context) => {
  const { data } = useBackend(context);
  const { current_bounty } = data;

  return (
    <Section
      fill
      title="Current Bounty"
      style={{ 'border-radius': '5px' }}
    >
      {!current_bounty ? (
        <NoticeBox>
          No bounty selected.
        </NoticeBox>
      ) : (
        <LabeledList vertical>
          <LabeledList.Item label="Requirements">
            {current_bounty.text_requirements}
          </LabeledList.Item>
          <LabeledList.Item label="Rewards">
            {current_bounty.text_rewards}
          </LabeledList.Item>
          <LabeledList.Item label="Requested by">
            {current_bounty.author_name}
          </LabeledList.Item>
        </LabeledList>)}
    </Section>
  );
};

const BountyInfo = (props, context) => {
  const { act, data } = useBackend(context);
  const { companies_by_name } = data;
  const { selectedCompany } = props;
  const currentCompany = companies_by_name[selectedCompany];
  if (!currentCompany) {
    return <NoticeBox>No company selected.</NoticeBox>;
  }

  return (
    <Stack fill vertical>
      <Stack.Item>
        <Section title={selectedCompany} grow>
          <Box mb="6px">{currentCompany.desc}</Box>
          <LabeledList vertical>
            <LabeledList.Item label="Maximum Bounty Level">
              {currentCompany.relationship}
            </LabeledList.Item>
            <LabeledList.Item label="Finished Bounties">
              {currentCompany.bounties_finished}
            </LabeledList.Item>
          </LabeledList>
        </Section>
      </Stack.Item>
      <Stack.Item grow>
        <Table>
          {currentCompany.bounties.map((bounty_row) => (
            <BountyRow bounty_row={bounty_row} key={bounty_row.iter} />
          ))}
        </Table>
      </Stack.Item>
    </Stack>
  );
};

const BountyRow = (props, context) => {
  const { act, data } = useBackend(context);
  const { current_bounty } = data;
  const { bounty_row } = props;

  return (
    <Table.Row>
      {bounty_row.bounties.map((bounty) => (
        <Table.Cell key={bounty.name}>
          <Section title={bounty.name} mb="6px">
            <LabeledList vertical>
              <LabeledList.Item label="Requirements">
                {bounty.text_requirements}
              </LabeledList.Item>
              <LabeledList.Item label="Rewards">
                {bounty.text_rewards}
              </LabeledList.Item>
            </LabeledList>
            <Button
              mt="9px"
              ml="33%"
              textAlign="center"
              selected={!!current_bounty && bounty.ref === current_bounty.ref}
              onClick={() => act('selected_bounty', { ref: bounty.ref })}
            >
              Take Bounty
            </Button>
          </Section>
        </Table.Cell>
      ))}
    </Table.Row>
  );
};
